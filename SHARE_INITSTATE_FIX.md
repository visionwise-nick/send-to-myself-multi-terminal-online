# 分享功能initState错误修复

## 问题描述

用户在使用分享功能时遇到了以下错误：

```
Share exception
Processing error: dependOnInheritedWidgetOfExactType<_LocalizationsScope>() or dependOnInheritedElement() was called before _ShareStatusScreenState.initState() completed.
```

这个错误是因为在 `ShareStatusScreen` 的 `initState()` 方法中过早使用了 `LocalizationHelper.of(context)`，而此时 Flutter 的 widget 树还没有完全初始化。

## 根本原因

1. **在initState()中使用context**: `ShareStatusScreen` 的 `_processShare()` 方法在 `initState()` 期间被调用
2. **LocalizationHelper过早调用**: `onProgressUpdate` 回调中使用了 `LocalizationHelper.of(context)` 来获取本地化文本
3. **Context未初始化**: 在 `initState()` 完成之前，context 相关的依赖还没有准备好

## 修复内容

### 1. ShareStatusScreen 修复
- **文件**: `lib/screens/share_status_screen.dart`
- **修改**: 移除 `LocalizationHelper.of(context)` 的使用，改用硬编码字符串进行状态检查
- **原因**: 在 `initState()` 期间不能使用 context 相关的操作

```dart
// 修复前（会导致错误）
if (status.contains(LocalizationHelper.of(context).allFilesSentComplete)) {
  // ...
}

// 修复后（使用硬编码字符串）
if (status.contains('所有文件发送完成') || status.contains('All files sent')) {
  // ...
}
```

### 2. BackgroundShareService 简化
- **文件**: `lib/services/background_share_service.dart`
- **修改1**: 移除 `handleShareIntent` 方法的 `BuildContext? context` 参数
- **修改2**: 移除 `_getLocalizedText` 辅助方法
- **修改3**: 移除不必要的导入（`flutter/material.dart` 和 `localization_helper.dart`）

### 3. 状态检查逻辑优化
支持中英文双语的状态检查：
- 中文：`所有文件发送完成`、`部分文件发送完成`、`分享失败`
- 英文：`All files sent`、`Text sent successfully`、`Share failed`

## 技术细节

### Flutter Widget 生命周期问题
在 Flutter 中，`initState()` 方法在 widget 的 context 完全初始化之前就被调用。此时：
- 不能使用 `MediaQuery.of(context)`
- 不能使用 `Theme.of(context)`
- 不能使用 `Localizations.of(context)`
- 不能使用任何依赖于 `InheritedWidget` 的操作

### 解决方案选择
有三种解决方案：
1. **使用 `didChangeDependencies()`**: 在这个方法中可以安全使用 context
2. **移到 `build()` 方法**: 在 build 方法中使用 context 是安全的
3. **移除 context 依赖**: 使用硬编码字符串或其他方式（我们选择了这种）

我们选择方案3是因为：
- 后台分享服务不应该依赖于 UI context
- 简化代码结构，提高可维护性
- 避免复杂的生命周期管理

## 测试结果

### 编译测试
```bash
flutter build macos --debug
# ✅ 编译成功，没有错误
```

### 国际化生成
```bash
flutter gen-l10n
# ✅ 成功生成，中文只有5个未翻译消息
```

## 预期效果

修复后，分享功能应该：
1. **不再出现 initState 错误**: 分享界面可以正常显示
2. **正常处理分享**: 文本和文件分享功能正常工作
3. **状态显示正确**: 进度和完成状态正确显示
4. **支持双语**: 中英文环境下都能正确工作

## 相关文件

- `lib/screens/share_status_screen.dart` - 分享状态界面
- `lib/services/background_share_service.dart` - 后台分享服务

## 提交信息

```
修复分享功能initState错误: 移除context参数依赖
- 移除ShareStatusScreen中LocalizationHelper的initState期间使用
- 简化BackgroundShareService，移除context依赖
- 使用硬编码字符串进行状态检查，支持中英文双语
- 修复Flutter widget生命周期相关的错误
``` 