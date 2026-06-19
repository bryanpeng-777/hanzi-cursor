// 由 tdesign-d2c 从 Figma 自动生成，作为 Flutter 实现的中间参考
// node-id: 1-2 | 框架: React（最终由 dev-assistant 翻译为 Flutter）
// Figma 画布：1536×1024 → 逻辑横屏 812×375（PinyinLearnScreen / 拼音学习）
import React from 'react';

const SX = 812 / 1536;
const SY = 375 / 1024;
const s = (v: number, axis: 'x' | 'y' = 'x') =>
  Math.round(v * (axis === 'x' ? SX : SY));

const ASSETS = {
  canvasBackdrop:
    '/Users/pengchao/assets/1-2/2ec5f780faf7ec52a5642285f649053e.png',
  panelBg: '/Users/pengchao/assets/1-2/49f603d8999b9bb221834e84b8f71696.png',
  gridBg: '/Users/pengchao/assets/1-2/687ecdfc7d6432edba31fe9f403cfb31.png',
  backBtn: '/Users/pengchao/assets/1-2/371e6997efc3988793cf4ec0b4e772e1.png',
  titleDecoLeft:
    '/Users/pengchao/assets/1-2/8038364964c58493a057823b2b6fbe07.png',
  titleDecoRight:
    '/Users/pengchao/assets/1-2/49ec886212395a3318b58f7f805b0170.png',
  headerAvatar:
    '/Users/pengchao/assets/1-2/d0306bda627008c12f86aa2d5ea41843.png',
  bottomBar: '/Users/pengchao/assets/1-2/93f6a10acd02edf8f9937cd2f60ae86c.png',
  manualModeBg:
    '/Users/pengchao/assets/1-2/b927aed5cb28a09cbb3a043e63bf60e8.png',
  manualModeIcon:
    '/Users/pengchao/assets/1-2/3399d0bd542056d96d0a7793d0d9923c.png',
  autoModeIcon:
    '/Users/pengchao/assets/1-2/b7f7409d0c2317fec43f0c8e1d719ef1.png',
  tabIndicator:
    '/Users/pengchao/assets/1-2/736976f58c7b72f5f83540869000dda1.png',
  tipIcon: '/Users/pengchao/assets/1-2/1dc74b03f67150892f6cc0fbd72c15c5.png',
  ttsIconB: '/Users/pengchao/assets/1-2/9426e1085ec86d7712d1261d9e729134.png',
};

const COLORS = {
  title: '#E6F0F8',
  tabActive: '#42BAC4',
  tabIdle: '#406485',
  manualLabel: '#D2F2EE',
  autoLabel: '#75889E',
  cardLetter: '#18496E',
  tipText: '#788799',
  statLabel: '#6688A2',
  statValue: '#65C8BD',
};

const INITIALS_ROW1 = ['b', 'p', 'm', 'f', 'd', 't', 'n', 'l'];
const INITIALS_ROW2 = ['g', 'k', 'h', 'j', 'q', 'x', 'zh', 'ch'];
const INITIALS_ROW3 = ['sh', 'r', 'z', 'c', 's', 'y', 'w', ''];

/** PinyinLearnScreen — 拼音学习（node 1-2，声母 Tab 默认） */
export default function PinyinLearnScreen() {
  return (
    <div
      data-name="PinyinLearnScreen"
      style={{
        position: 'relative',
        width: 812,
        height: 375,
        overflow: 'hidden',
        fontFamily: 'Inter, "Noto Sans SC", sans-serif',
      }}
    >
      {/* Canvas backdrop */}
      <img
        src={ASSETS.canvasBackdrop}
        alt=""
        style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
      />

      {/* Header — Groups @ top */}
      <div
        data-name="HeaderBar"
        style={{
          position: 'absolute',
          left: 0,
          top: 0,
          width: 812,
          height: s(138, 'y'),
        }}
      >
        <button
          type="button"
          data-name="BackButton"
          style={{
            position: 'absolute',
            left: s(119),
            top: s(47, 'y'),
            width: s(84),
            height: s(85, 'y'),
            border: 'none',
            background: `url(${ASSETS.backBtn}) center/cover no-repeat`,
          }}
        />
        <img
          src={ASSETS.titleDecoLeft}
          alt=""
          style={{
            position: 'absolute',
            left: s(552),
            top: s(54, 'y'),
            width: s(41),
            height: s(37, 'y'),
          }}
        />
        <div
          data-name="HeaderTitle"
          style={{
            position: 'absolute',
            left: s(622),
            top: s(40, 'y'),
            width: s(300),
            height: s(87, 'y'),
            color: COLORS.title,
            fontWeight: 600,
            fontSize: s(73),
            lineHeight: `${s(88, 'y')}px`,
            display: 'flex',
            alignItems: 'center',
          }}
        >
          拼音学习
        </div>
        <img
          src={ASSETS.titleDecoRight}
          alt=""
          style={{
            position: 'absolute',
            left: s(947),
            top: s(55, 'y'),
            width: s(42),
            height: s(39, 'y'),
          }}
        />
        <img
          src={ASSETS.headerAvatar}
          alt=""
          style={{
            position: 'absolute',
            left: s(1329),
            top: s(49, 'y'),
            width: s(82),
            height: s(83, 'y'),
          }}
        />
      </div>

      {/* Main panel */}
      <div
        data-name="MainPanel"
        style={{
          position: 'absolute',
          left: s(76),
          top: s(132, 'y'),
          width: s(1459),
          height: s(883, 'y'),
        }}
      >
        <img
          src={ASSETS.panelBg}
          alt=""
          style={{
            position: 'absolute',
            left: s(51),
            top: s(3, 'y'),
            width: s(1273),
            height: s(817, 'y'),
          }}
        />

        {/* Mode toggle */}
        <button
          type="button"
          data-name="ManualModeButton"
          style={{
            position: 'absolute',
            left: s(425),
            top: s(27, 'y'),
            width: s(268),
            height: s(75, 'y'),
            border: 'none',
            background: `url(${ASSETS.manualModeBg}) center/cover no-repeat`,
          }}
        >
          <span
            style={{
              position: 'absolute',
              left: s(110),
              top: s(23, 'y'),
              color: COLORS.manualLabel,
              fontSize: s(26),
              lineHeight: `${s(31, 'y')}px`,
            }}
          >
            手动模式
          </span>
        </button>
        <button
          type="button"
          data-name="AutoModeButton"
          style={{
            position: 'absolute',
            left: s(692),
            top: s(27, 'y'),
            width: s(267),
            height: s(75, 'y'),
            border: 'none',
            background: 'rgba(228,233,238,1)',
            borderRadius: '0 30px 28px 0',
          }}
        >
          <span
            style={{
              position: 'absolute',
              left: s(109),
              top: s(24, 'y'),
              color: COLORS.autoLabel,
              fontSize: s(25),
              lineHeight: `${s(30, 'y')}px`,
            }}
          >
            自动模式
          </span>
        </button>

        {/* Tab bar — 声母 / 韵母 / 四声 */}
        <div
          data-name="TabBar"
          style={{
            position: 'absolute',
            left: s(82),
            top: s(116, 'y'),
            width: s(1358),
            height: s(67, 'y'),
          }}
        >
          <span
            style={{
              position: 'absolute',
              left: s(218),
              top: s(20, 'y'),
              color: COLORS.tabActive,
              fontWeight: 500,
              fontSize: s(28),
              lineHeight: `${s(34, 'y')}px`,
            }}
          >
            声母
          </span>
          <span
            style={{
              position: 'absolute',
              left: s(581),
              top: s(20, 'y'),
              color: COLORS.tabIdle,
              fontWeight: 500,
              fontSize: s(27),
              lineHeight: `${s(33, 'y')}px`,
            }}
          >
            韵母
          </span>
          <span
            style={{
              position: 'absolute',
              left: s(932),
              top: s(19, 'y'),
              color: COLORS.tabIdle,
              fontWeight: 500,
              fontSize: s(27),
              lineHeight: `${s(33, 'y')}px`,
            }}
          >
            四声
          </span>
          <img
            src={ASSETS.tabIndicator}
            alt=""
            style={{
              position: 'absolute',
              left: s(209),
              top: s(70, 'y'),
              width: s(76),
              height: s(6, 'y'),
            }}
          />
        </div>

        {/* Grid area */}
        <div
          data-name="InitialsPanel"
          style={{
            position: 'absolute',
            left: s(81),
            top: s(108, 'y'),
            width: s(1218),
            height: s(544, 'y'),
          }}
        >
          <img
            src={ASSETS.gridBg}
            alt=""
            style={{
              position: 'absolute',
              left: 0,
              top: s(5, 'y'),
              width: s(1218),
              height: s(531, 'y'),
            }}
          />
          {/* Row 1 — b card with TTS (test key: hanzi-pinyin-learn-tts-initial-b) */}
          <button
            type="button"
            data-name="PinyinCard_b"
            data-tts-key="hanzi-pinyin-learn-tts-initial-b"
            style={{
              position: 'absolute',
              left: s(22),
              top: s(92, 'y'),
              width: s(144),
              height: s(146, 'y'),
              border: 'none',
              background: 'rgba(253,253,253,1)',
              borderRadius: 18,
              outline: '1px solid rgba(152,208,199,1)',
            }}
          >
            <span
              style={{
                position: 'absolute',
                left: s(58),
                top: s(26, 'y'),
                fontWeight: 600,
                fontSize: s(54),
                color: COLORS.cardLetter,
              }}
            >
              b
            </span>
            <img
              src={ASSETS.ttsIconB}
              alt="TTS"
              style={{
                position: 'absolute',
                left: s(55),
                top: s(91, 'y'),
                width: s(37),
                height: s(37, 'y'),
              }}
            />
          </button>
          {/* Additional cards: p,m,f,... rendered similarly in Flutter GridView */}
        </div>

        {/* Bottom stats */}
        <div
          data-name="StatsBar"
          style={{
            position: 'absolute',
            left: s(97),
            top: s(677, 'y'),
            width: s(1359),
            height: s(121, 'y'),
          }}
        >
          <img
            src={ASSETS.tipIcon}
            alt=""
            style={{
              position: 'absolute',
              left: s(32),
              top: s(24, 'y'),
              width: s(76),
              height: s(73, 'y'),
            }}
          />
          <p
            style={{
              position: 'absolute',
              left: s(117),
              top: s(28, 'y'),
              margin: 0,
              color: COLORS.tipText,
              fontSize: s(19),
              lineHeight: '150%',
            }}
          >
            点击卡片可以听发音哦~
            <br />
            每天学一学，拼音真有趣！
          </p>
        </div>
      </div>

      <img
        src={ASSETS.bottomBar}
        alt=""
        style={{
          position: 'absolute',
          left: s(13),
          top: s(947, 'y'),
          width: s(527),
          height: s(77, 'y'),
        }}
      />
    </div>
  );
}
