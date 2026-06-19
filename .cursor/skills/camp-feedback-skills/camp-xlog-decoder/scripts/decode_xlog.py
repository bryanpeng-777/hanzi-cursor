#!/usr/bin/env python3
"""营地 mars xlog 通用解码脚本。

同时支持：
- Android nocrypt（MAGIC 0x08/0x09）：无需密钥，直接 zlib 解压
- ECC 加密（MAGIC 0x07）：需要 PRIV_KEY（secp256k1 ECDH 私钥）
- TEA 加密 + 压缩（MAGIC 0x04/0x05）：需要 PRIV_KEY
- 无压缩（MAGIC 0x03/0x06）：需要 PRIV_KEY（TEA 解密后直接输出）

用法：
    python3 decode_xlog.py <输入xlog> [输出路径]
    python3 decode_xlog.py <目录>           # 处理目录下所有 .xlog

环境变量（可选）：
    CAMP_XLOG_PRIV_KEY   secp256k1 私钥（64 hex chars）。
                         未设置时 ECC 加密的日志会解码失败（nocrypt 不影响）。

依赖：
    - 纯 nocrypt 模式：无额外依赖
    - ECC 模式：需要 pyelliptic（pip install pyelliptic）
"""
import sys
import os
import glob
import zlib
import struct
import binascii
import traceback

from cryptography.hazmat.primitives.asymmetric.ec import (
    SECP256K1, ECDH,
    EllipticCurvePublicNumbers,
    EllipticCurvePrivateNumbers,
)
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.backends import default_backend

# ============================================================
# 密钥配置
# ============================================================

# 服务端 secp256k1 ECDH 私钥（64 hex chars）
# 优先从环境变量读取；未设置时使用硬编码值
PRIV_KEY = os.environ.get("CAMP_XLOG_PRIV_KEY", "0c02cd45888dde8cdf888a0f2727ddf9e846d8b1db5b2e9adee2489e97c08fb9")

# 公钥（通常不需要，client pubkey 在每个 log block 的 header 里携带）
PUB_KEY = ""

# ============================================================
# Magic 常量
# ============================================================

MAGIC_NO_COMPRESS_START = 0x03          # TEA 加密，无压缩
MAGIC_COMPRESS_START = 0x04             # TEA 加密 + zlib
MAGIC_COMPRESS_START1 = 0x05            # TEA 加密 + 分段 zlib
MAGIC_NO_COMPRESS_START1 = 0x06         # ECC + 无压缩
MAGIC_COMPRESS_START2 = 0x07            # ECC + zlib（iOS 常用）
MAGIC_NO_COMPRESS_NO_CRYPT_START = 0x08 # 无加密无压缩（Android nocrypt）
MAGIC_COMPRESS_NO_CRYPT_START = 0x09    # 无加密 + zlib（Android nocrypt 压缩）

MAGIC_END = 0x00

lastseq = 0


# ============================================================
# TEA 解密
# ============================================================

def tea_decipher(v, k):
    op = 0xFFFFFFFF
    v0, v1 = struct.unpack('=LL', v[0:8])
    k1, k2, k3, k4 = struct.unpack('=LLLL', k[0:16])
    delta = 0x9E3779B9
    s = (delta << 4) & op
    for i in range(16):
        v1 = (v1 - (((v0 << 4) + k3) ^ (v0 + s) ^ ((v0 >> 5) + k4))) & op
        v0 = (v0 - (((v1 << 4) + k1) ^ (v1 + s) ^ ((v1 >> 5) + k2))) & op
        s = (s - delta) & op
    return struct.pack('=LL', v0, v1)


def tea_decrypt(v, k):
    num = len(v) // 8 * 8
    ret = bytearray()
    for i in range(0, num, 8):
        x = tea_decipher(v[i:i + 8], k)
        ret += x
    ret += v[num:]
    return ret


# ============================================================
# ECDH 密钥交换（替代 pyelliptic）
# ============================================================

def _ecdh_get_tea_key(priv_key_hex: str, pubkey_x: bytes, pubkey_y: bytes) -> bytes:
    """用服务端私钥 + 客户端公钥做 ECDH，返回 shared secret 作为 TEA key。"""
    from cryptography.hazmat.primitives.asymmetric.ec import derive_private_key
    curve = SECP256K1()
    backend = default_backend()

    # 从私钥标量直接构建（自动推导公钥）
    private_key = derive_private_key(int(priv_key_hex, 16), curve, backend)

    # 从 header 提取的 x/y 构建 client 公钥
    peer_pub_key = EllipticCurvePublicNumbers(
        int.from_bytes(pubkey_x, 'big'),
        int.from_bytes(pubkey_y, 'big'),
        curve,
    ).public_key(backend)

    # ECDH → shared secret
    return private_key.exchange(ECDH(), peer_pub_key)


# ============================================================
# Buffer 校验
# ============================================================

def IsGoodLogBuffer(_buffer, _offset, count):
    if _offset == len(_buffer):
        return (True, '')

    magic_start = _buffer[_offset]
    if magic_start in {MAGIC_NO_COMPRESS_START, MAGIC_COMPRESS_START, MAGIC_COMPRESS_START1}:
        crypt_key_len = 4
    elif magic_start in {MAGIC_COMPRESS_START2, MAGIC_NO_COMPRESS_START1,
                         MAGIC_NO_COMPRESS_NO_CRYPT_START, MAGIC_COMPRESS_NO_CRYPT_START}:
        crypt_key_len = 64
    else:
        return (False, f'_buffer[{_offset}]:{_buffer[_offset]} != MAGIC_NUM_START')

    header_len = 1 + 2 + 1 + 1 + 4 + crypt_key_len

    if _offset + header_len + 1 + 1 > len(_buffer):
        return (False, f'offset:{_offset} > len(buffer):{len(_buffer)}')

    length = struct.unpack_from("I", memoryview(_buffer)[_offset + header_len - 4 - crypt_key_len:])[0]

    if _offset + header_len + length + 1 > len(_buffer):
        return (False, f'log length:{length}, end pos > len(buffer):{len(_buffer)}')

    if MAGIC_END != _buffer[_offset + header_len + length]:
        return (False, f'log end marker mismatch')

    if count <= 1:
        return (True, '')
    else:
        return IsGoodLogBuffer(_buffer, _offset + header_len + length + 1, count - 1)


def GetLogStartPos(_buffer, _count):
    offset = 0
    while True:
        if offset >= len(_buffer):
            break
        if _buffer[offset] in {MAGIC_NO_COMPRESS_START, MAGIC_NO_COMPRESS_START1,
                                MAGIC_COMPRESS_START, MAGIC_COMPRESS_START1,
                                MAGIC_COMPRESS_START2, MAGIC_COMPRESS_NO_CRYPT_START,
                                MAGIC_NO_COMPRESS_NO_CRYPT_START}:
            if IsGoodLogBuffer(_buffer, offset, _count)[0]:
                return offset
        offset += 1
    return -1


# ============================================================
# 核心解码
# ============================================================

def DecodeBuffer(_buffer, _offset, _outbuffer):
    if _offset >= len(_buffer):
        return -1

    ret = IsGoodLogBuffer(_buffer, _offset, 1)
    if not ret[0]:
        fixpos = GetLogStartPos(_buffer[_offset:], 1)
        if fixpos == -1:
            return -1
        else:
            _outbuffer.extend(f"[F]decode_xlog.py decode error len={fixpos}, result:{ret[1]}\n".encode('utf-8'))
            _offset += fixpos

    magic_start = _buffer[_offset]
    if magic_start in {MAGIC_NO_COMPRESS_START, MAGIC_COMPRESS_START, MAGIC_COMPRESS_START1}:
        crypt_key_len = 4
    elif magic_start in {MAGIC_COMPRESS_START2, MAGIC_NO_COMPRESS_START1,
                         MAGIC_NO_COMPRESS_NO_CRYPT_START, MAGIC_COMPRESS_NO_CRYPT_START}:
        crypt_key_len = 64
    else:
        _outbuffer.extend(f'[F]decode_xlog.py unknown magic: 0x{magic_start:02x}\n'.encode('utf-8'))
        return -1

    header_len = 1 + 2 + 1 + 1 + 4 + crypt_key_len
    length = struct.unpack_from("I", memoryview(_buffer)[_offset + header_len - 4 - crypt_key_len:])[0]
    tmpbuffer = bytearray(length)

    seq = struct.unpack_from("H", memoryview(_buffer)[_offset + header_len - 4 - crypt_key_len - 2 - 2:])[0]
    begin_hour = struct.unpack_from("c", memoryview(_buffer)[_offset + header_len - 4 - crypt_key_len - 1 - 1:])[0]
    end_hour = struct.unpack_from("c", memoryview(_buffer)[_offset + header_len - 4 - crypt_key_len - 1:])[0]

    global lastseq
    if seq != 0 and seq != 1 and lastseq != 0 and seq != (lastseq + 1):
        _outbuffer.extend(f"[F]decode_xlog.py log seq:{lastseq + 1}-{seq - 1} is missing\n".encode('utf-8'))

    if seq != 0:
        lastseq = seq

    tmpbuffer[:] = _buffer[_offset + header_len:_offset + header_len + length]

    try:
        decompressor = zlib.decompressobj(-zlib.MAX_WBITS)

        if magic_start == MAGIC_NO_COMPRESS_NO_CRYPT_START:
            # 无加密无压缩：直接输出
            pass

        elif magic_start == MAGIC_COMPRESS_NO_CRYPT_START:
            # 无加密 + zlib 压缩
            tmpbuffer = decompressor.decompress(bytes(tmpbuffer))

        elif magic_start == MAGIC_NO_COMPRESS_START1:
            # ECC + 无压缩
            if not PRIV_KEY:
                raise RuntimeError("ECC 模式需要 PRIV_KEY（请设置 CAMP_XLOG_PRIV_KEY 环境变量）")
            pubkey_x = memoryview(_buffer)[_offset + header_len - crypt_key_len:_offset + header_len - crypt_key_len // 2].tobytes()
            pubkey_y = memoryview(_buffer)[_offset + header_len - crypt_key_len // 2:_offset + header_len].tobytes()
            tea_key = _ecdh_get_tea_key(PRIV_KEY, pubkey_x, pubkey_y)
            tmpbuffer = tea_decrypt(tmpbuffer, tea_key)

        elif magic_start == MAGIC_COMPRESS_START2:
            # ECC + zlib（iOS 常用）
            if not PRIV_KEY:
                raise RuntimeError("ECC 模式需要 PRIV_KEY（请设置 CAMP_XLOG_PRIV_KEY 环境变量）")
            pubkey_x = memoryview(_buffer)[_offset + header_len - crypt_key_len:_offset + header_len - crypt_key_len // 2].tobytes()
            pubkey_y = memoryview(_buffer)[_offset + header_len - crypt_key_len // 2:_offset + header_len].tobytes()
            tea_key = _ecdh_get_tea_key(PRIV_KEY, pubkey_x, pubkey_y)
            tmpbuffer = tea_decrypt(tmpbuffer, tea_key)
            tmpbuffer = decompressor.decompress(bytes(tmpbuffer))

        elif magic_start in {MAGIC_COMPRESS_START, MAGIC_NO_COMPRESS_START}:
            # 旧版 TEA（4 字节 key）— 极少见，兼容保留
            tmpbuffer = decompressor.decompress(bytes(tmpbuffer)) if magic_start == MAGIC_COMPRESS_START else tmpbuffer

        elif magic_start == MAGIC_COMPRESS_START1:
            # 分段压缩
            decompress_data = bytearray()
            while len(tmpbuffer) > 0:
                single_log_len = struct.unpack_from("H", memoryview(tmpbuffer)[0:2])[0]
                decompress_data.extend(tmpbuffer[2:single_log_len + 2])
                tmpbuffer[:] = tmpbuffer[single_log_len + 2:]
            tmpbuffer = decompressor.decompress(bytes(decompress_data))

    except RuntimeError:
        raise  # PRIV_KEY 缺失错误向上传播
    except Exception as e:
        traceback.print_exc()
        _outbuffer.extend(f"[F]decode_xlog.py decompress err, {str(e)}\n".encode('utf-8'))
        return _offset + header_len + length + 1

    if isinstance(tmpbuffer, bytearray):
        _outbuffer.extend(tmpbuffer)
    else:
        _outbuffer.extend(tmpbuffer if isinstance(tmpbuffer, bytes) else bytes(tmpbuffer))

    return _offset + header_len + length + 1


# ============================================================
# 文件处理
# ============================================================

def ParseFile(_file, _outfile):
    with open(_file, "rb") as fp:
        _buffer = bytearray(os.path.getsize(_file))
        fp.readinto(_buffer)

    startpos = GetLogStartPos(_buffer, 2)
    if startpos == -1:
        return False

    outbuffer = bytearray()

    while True:
        startpos = DecodeBuffer(_buffer, startpos, outbuffer)
        if startpos == -1:
            break

    if len(outbuffer) == 0:
        return False

    with open(_outfile, "wb") as fpout:
        fpout.write(outbuffer)
    return True


def main(args):
    global lastseq

    if len(args) == 0:
        print(f"用法: python3 {sys.argv[0]} <xlog文件或目录> [输出路径]", file=sys.stderr)
        sys.exit(1)

    if len(args) == 1:
        if os.path.isdir(args[0]):
            filelist = glob.glob(args[0] + "/*.xlog")
            for filepath in filelist:
                lastseq = 0
                outpath = filepath + ".log"
                if ParseFile(filepath, outpath):
                    print(outpath)
                else:
                    print(f"[SKIP] {filepath}: 无有效日志数据", file=sys.stderr)
        else:
            outpath = args[0] + ".log"
            if ParseFile(args[0], outpath):
                print(outpath)
            else:
                print(f"[ERROR] 解码失败: {args[0]}", file=sys.stderr)
                sys.exit(1)
    elif len(args) == 2:
        if ParseFile(args[0], args[1]):
            print(args[1])
        else:
            print(f"[ERROR] 解码失败: {args[0]}", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
