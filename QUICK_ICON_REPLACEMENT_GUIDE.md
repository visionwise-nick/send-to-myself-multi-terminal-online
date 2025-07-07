# 快速图标替换指南 🎨

## 🚀 快速开始

### 1. 准备图标文件
- 准备一个 **1024x1024** 像素的PNG图标文件
- 将文件命名为 `app_icon.png`
- 放置到 `assets/icons/` 目录

### 2. 运行命令
```bash
# 生成所有平台的图标
flutter pub run flutter_launcher_icons
```

### 3. 测试效果
```bash
# 重新编译应用
flutter clean
flutter build apk --debug  # Android
flutter build ios --debug  # iOS
flutter build macos --debug # macOS
```

## 📱 支持的平台
- ✅ **Android** - 支持自适应图标
- ✅ **iOS** - 支持所有设备尺寸
- ✅ **macOS** - 支持Retina显示
- ✅ **Web** - PWA图标
- ✅ **Windows** - 应用图标
- ✅ **Linux** - 应用图标

## 🎯 Android自适应图标（可选）
如需支持Android自适应图标：
1. 创建透明背景的前景图标：`app_icon_foreground.png`
2. 放置到 `assets/icons/` 目录
3. 运行生成命令

## ⚡ 当前配置
已为您配置好以下设置：
- 主图标路径：`assets/icons/app_icon.png`
- Android自适应前景：`assets/icons/app_icon_foreground.png`
- Android背景色：白色 (#ffffff)
- Web主题色：黑色 (#000000)

## 🔧 故障排除
- **图标未更新**：运行 `flutter clean` 后重新编译
- **Android图标异常**：检查前景图标是否透明背景
- **生成失败**：确保图标文件存在且为PNG格式

## 📝 完整文档
详细说明请查看：[APP_ICON_REPLACEMENT_GUIDE.md](./APP_ICON_REPLACEMENT_GUIDE.md) 