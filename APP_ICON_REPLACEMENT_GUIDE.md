# APP图标替换指南

## 概述
本指南详细介绍如何为Flutter应用"Send To Myself"替换APP图标。我们使用`flutter_launcher_icons`插件来自动化图标生成过程。

## 准备工作

### 1. 图标文件要求
您需要准备以下图标文件：

#### 主图标文件
- **文件名**: `app_icon.png`
- **尺寸**: 1024x1024像素
- **格式**: PNG
- **背景**: 可以是透明或不透明
- **放置位置**: `assets/icons/app_icon.png`

#### 自适应图标前景（Android专用）
- **文件名**: `app_icon_foreground.png`
- **尺寸**: 1024x1024像素
- **格式**: PNG
- **背景**: 必须透明
- **内容**: 图标的前景部分，周围留有安全区域
- **放置位置**: `assets/icons/app_icon_foreground.png`

### 2. 图标设计建议
- **安全区域**: 图标内容应在中心的70%区域内
- **简洁性**: 避免过于复杂的细节
- **对比度**: 确保在不同背景下都清晰可见
- **一致性**: 保持品牌风格统一

## 替换步骤

### 步骤1: 准备图标文件
1. 将您的1024x1024像素主图标保存为 `assets/icons/app_icon.png`
2. 如果需要Android自适应图标，将前景图标保存为 `assets/icons/app_icon_foreground.png`

### 步骤2: 安装依赖
```bash
flutter pub get
```

### 步骤3: 生成图标
```bash
flutter pub run flutter_launcher_icons
```

### 步骤4: 验证结果
生成完成后，检查以下目录：
- `android/app/src/main/res/` - Android图标
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` - iOS图标
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/` - macOS图标
- `web/icons/` - Web图标
- `windows/runner/resources/` - Windows图标

### 步骤5: 测试应用
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# macOS
flutter run -d macos

# Web
flutter run -d web-server

# Windows
flutter run -d windows
```

## 当前配置说明

### Android配置
- 支持自适应图标
- 背景色: 白色 (#ffffff)
- 前景图标: 透明背景PNG

### iOS配置
- 生成所有必需的图标尺寸
- 支持iOS 7+所有设备

### macOS配置
- 生成macOS应用图标
- 支持Retina显示

### Web配置
- 生成PWA图标
- 背景色: 白色 (#ffffff)
- 主题色: 黑色 (#000000)

### Windows配置
- 生成Windows应用图标
- 图标尺寸: 48像素

### Linux配置
- 生成Linux应用图标
- 标准PNG格式

## 高级配置

### 自定义特定平台图标
如果您需要为特定平台使用不同的图标，可以在`pubspec.yaml`中修改配置：

```yaml
flutter_launcher_icons:
  android:
    generate: true
    image_path: "assets/icons/android_icon.png"
  ios:
    generate: true
    image_path: "assets/icons/ios_icon.png"
  # ... 其他平台配置
```

### 禁用特定平台
如果您不需要为某个平台生成图标，可以设置为false：

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  macos: false    # 禁用macOS图标生成
  web: false      # 禁用Web图标生成
  windows: true
  linux: true
```

## 常见问题解决

### Q1: 图标显示不正确
- 检查图标文件是否存在且路径正确
- 确保图标文件格式为PNG
- 验证图标尺寸是否为1024x1024

### Q2: Android自适应图标问题
- 确保前景图标有透明背景
- 检查前景图标内容是否在安全区域内
- 验证背景色配置是否正确

### Q3: 生成失败
- 运行 `flutter clean` 清理项目
- 重新运行 `flutter pub get`
- 检查终端错误信息

### Q4: 部分平台图标未更新
- 删除对应平台的图标文件
- 重新运行图标生成命令
- 完全重新构建应用

## 文件结构示例

```
assets/
└── icons/
    ├── app_icon.png              # 主图标 (1024x1024)
    └── app_icon_foreground.png   # Android前景图标 (1024x1024)

android/app/src/main/res/
├── mipmap-hdpi/
├── mipmap-mdpi/
├── mipmap-xhdpi/
├── mipmap-xxhdpi/
├── mipmap-xxxhdpi/
└── mipmap-anydpi-v26/

ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Contents.json
├── Icon-App-20x20@1x.png
├── Icon-App-20x20@2x.png
└── ...

# 其他平台类似
```

## 注意事项

1. **版权**: 确保您有权使用所选图标
2. **备份**: 替换前备份原始图标文件
3. **测试**: 在所有目标平台上测试新图标
4. **App Store**: iOS图标需要遵守App Store审核指南
5. **Play Store**: Android图标需要遵守Google Play政策

## 完成后的步骤

1. 提交更改到版本控制系统
2. 更新应用版本号
3. 重新构建并测试应用
4. 部署到各平台应用商店

---

**注意**: 图标替换后，您需要重新编译应用才能看到更改。在开发过程中，某些平台可能需要完全重新安装应用才能显示新图标。 