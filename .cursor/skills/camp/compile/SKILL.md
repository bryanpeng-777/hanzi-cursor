---
name: compile
description: 编译专家，支持 Flutter 模块和 iOS 应用的编译构建。当用户提到"编译"、"构建"、"build"、"打包"时触发。提供完整的编译指导，包括：1) Flutter 模块编译（代码生成、iOS framework 构建），2) iOS 应用构建（不同模式：Debug/Dailybuild/Adhoc/Release），3) 常见编译问题排查，4) 编译命令和参数说明。
---

# 编译专家

## 项目架构

这是一个混合移动应用项目，包含：
- **Flutter 模块**：`flutter_module/` - 嵌入 iOS 的混合模块
- **iOS 应用**：`social-ios/` - iOS 原生应用

## Flutter 模块编译

### 代码生成

在编译 Flutter 模块前，需要运行代码生成器：

```bash
# 完整构建（所有生成器）
python3 build_runner.py

# 单文件生成
python3 build_runner.py --only filename.dart
```

**支持的生成器**：
- `trouter`: 生成路由代码
- `tica`: 生成 TICA 模型文件
- `asset`: 生成资源引用
- `database`: 生成数据库代码
- `onedata`: 生成 OneDataData 代码
- `webview`: 生成 WebView 代码

### 编译 iOS Framework

Flutter 模块需要编译为 iOS framework 才能被 iOS 应用集成：

```bash
./tools/build-ios-framework.sh
```

**脚本说明**：
- 输出目录：`build/Output/`
- Flutter SDK 版本：3.7.1（在脚本中配置）
- 自动清理旧构建产物
- 支持代码混淆（--obfuscate）

## iOS 模拟器编译（本地测试用）

无需真机，直接编译到模拟器运行：

```bash
# 查看可用模拟器
xcrun simctl list devices available | grep "iPhone"

# 编译模拟器版本
cd /Users/bryanpeng/work_tree_bugfix/social-ios/xcodeproj
xcodebuild \
  -workspace GameApp.xcworkspace \
  -scheme SmobaHelper \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=<simulator_uuid>' \
  build ONLY_ACTIVE_ARCH=YES

# 安装并启动（项目产物在 CustomDerived，非默认 DerivedData）
APP_PATH="/Users/bryanpeng/work_tree_bugfix/CustomDerived/Build/Products/Debug-iphonesimulator/SmobaHelper.app"
xcrun simctl install <sim_id> "$APP_PATH"
xcrun simctl launch <sim_id> com.tencent.smobagamehelperdebug
```

**注意**：项目配置了自定义 `CustomDerived` 路径，产物在 `work_tree_bugfix/CustomDerived/Build/Products/Debug-iphonesimulator/`，不在默认 `~/Library/Developer/Xcode/DerivedData`。

---

## iOS 应用编译

### 编译脚本

iOS 应用编译使用统一的构建脚本：

```bash
cd /Users/bryanpeng/work/social-ios
./devops/build.sh
```

### 编译模式

通过环境变量 `BUILD_MODE` 指定编译模式：

| BUILD_MODE | 配置 | 说明 |
|-----------|--------|------|
| Debug | Release | Debug 模式，用于开发调试 |
| Dailybuild | DailyBuild | 每日构建版本，用于测试 |
| Adhoc | Adhoc | Adhoc 分发版本，用于内测 |
| Release | Release | 正式发布版本，用于上线 |

### 使用示例

```bash
# Debug 编译
BUILD_MODE=Debug ./devops/build.sh

# Dailybuild 编译
BUILD_MODE=Dailybuild ./devops/build.sh

# Adhoc 编译
BUILD_MODE=Adhoc ./devops/build.sh

# Release 编译
./devops/build.sh

# 带 TestFlight 的编译
BUILD_TESTFLIGHT=1 ./devops/build.sh

# 灵度模式编译
BUILD_MODE=Performance ./devops/build.sh
```

### 环境变量

| 变量 | 说明 | 可选值 |
|------|------|--------|
| BUILD_MODE | 编译模式 | Debug/Dailybuild/Adhoc/Release |
| BUILD_TESTFLIGHT | 是否上传 TestFlight | 1（是）/ 0（否） |
| LINXI_PRIVACY | 隐私模式 | 1（是）/ 0（否） |

## 常见编译问题

### Flutter 模块问题

**问题 1：flutter clean 或 flutter pub get 失败**
```
error: failed to clean or pub get
```
**解决方案**：
- 检查网络连接
- 检查 Flutter 版本（建议 3.16.9）
- 检查依赖源（使用腾讯镜像）

**问题 2：代码生成失败**
```
error: build_runner.py failed
```
**解决方案**：
- 反复执行：`python3 build_runner.py`
- 清理缓存：`flutter clean`
- 检查代码语法错误

**问题 3：单个生成器失败**
```
error: XXX generator failed
```
**解决方案**：
- 单独运行生成器：`python3 build_runner.py --only filename.dart`
- 检查对应文件的格式

### iOS 问题

**问题 1：CocoaPods 安装失败**
```
error: pod install failed
```
**解决方案**：
- 更新 repo：`bundle exec pod install --repo-update`
- 清理缓存：`bundle exec pod cache clean`
- 检查网络连接

**问题 2：依赖找不到**
```
error: Could not find dependency
```
**解决方案**：
- 检查 Podfile 配置
- 更新 CocoaPods：`gem install cocoapods`
- 删除 Podfile.lock 重试

## 完整编译流程

### Flutter 模块编译

进入 flutter_module 文件夹，执行以下命令（可能需要反复执行直到成功）：

```bash
cd /Users/bryanpeng/work/flutter_module

# 清理并更新依赖
flutter clean && flutter pub get

# 代码生成（可能需要多次执行直到成功）
python3 build_runner.py
```

**说明**：
- `flutter clean`: 清理编译缓存
- `flutter pub get`: 更新依赖包
- `python3 build_runner.py`: 运行代码生成器
- 这两个命令可能需要反复执行才能成功，需确保两个都执行成功

### iOS 应用编译

进入 iOS Native 工程，安装 CocoaPods 依赖：

```bash
cd /Users/bryanpeng/work/social-ios/xcodeproj
bundle exec pod install --repo-update
```

### 完整编译示例

```bash
# 步骤1: 编译 Flutter 模块
cd /Users/bryanpeng/work/flutter_module
flutter clean && flutter pub get
python3 build_runner.py

# 步骤2: 安装 iOS 依赖
cd /Users/bryanpeng/work/social-ios/xcodeproj
bundle exec pod install --repo-update
```

## 输出产物

### Flutter Module

| 路径 | 内容 |
|------|------|
| `build/Output/Release/` | Release framework |
| `build/Output/Debug/` | Debug framework |

### iOS App

| 路径 | 内容 |
|------|------|
| `build/DailyBuild-iphoneos/` | Dailybuild IPA |
| `build/Adhoc-iphoneos/` | Adhoc IPA |
| `build/Release-iphoneos/` | Release IPA |

## 参考资料

### 项目文档

- `/Users/bryanpeng/work/CLAUDE.md` - 项目开发指南
- `/Users/bryanpeng/work/social-ios/devops/build.sh` - 编译脚本
- `/Users/bryanpeng/work/flutter_module/tools/build-ios-framework.sh` - Framework 编译脚本

### 构建系统

- Flutter：https://docs.flutter.dev/build
- Xcode：https://developer.apple.com/documentation/xcode/building-your-project
- CocoaPods：https://cocoapods.org/
