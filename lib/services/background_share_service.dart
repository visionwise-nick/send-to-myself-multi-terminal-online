import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'local_storage_service.dart';
import '../utils/localization_helper.dart';

/// 后台分享服务 - 专门处理分享Intent而不启动完整应用
class BackgroundShareService {
  static final BackgroundShareService _instance = BackgroundShareService._internal();
  factory BackgroundShareService() => _instance;
  BackgroundShareService._internal();
  
  /// 安全获取本地化文本的辅助方法
  static String _getLocalizedText(BuildContext? context, String Function(dynamic) getter, String fallback) {
    if (context != null) {
      try {
        return getter(LocalizationHelper.of(context));
      } catch (e) {
        print('获取本地化文本失败: $e');
      }
    }
    return fallback;
  }

  static const MethodChannel _channel = MethodChannel('com.example.send_to_myself/share');
  
  /// 处理分享Intent（带进度回调）
  static Future<bool> handleShareIntent({Function(String, String)? onProgressUpdate, BuildContext? context}) async {
    try {
      print('🔍 检查是否为分享Intent...');
      onProgressUpdate?.call('正在检测分享内容...', '检查是否为分享Intent');
      
      // 检查是否为分享Intent
      final bool? isShare = await _channel.invokeMethod('isShareIntent');
      if (isShare != true) {
        print('❌ 不是分享Intent，跳过处理');
        onProgressUpdate?.call('❌ 未检测到分享内容', '请重新尝试分享');
        return false;
      }
      
      print('✅ 检测到分享Intent，开始后台处理...');
      onProgressUpdate?.call('检测到分享内容', '正在获取分享数据...');
      
      // 获取分享数据
      final Map<dynamic, dynamic>? shareData = await _channel.invokeMethod('getSharedData');
      if (shareData == null) {
        print('❌ 没有分享数据');
        onProgressUpdate?.call('❌ 获取分享数据失败', '没有检测到有效的分享内容');
        return false;
      }
      
      print('📥 获取到分享数据: $shareData');
      
      // 后台处理分享
      final success = await _handleShareInBackground(shareData, onProgressUpdate: onProgressUpdate);
      
      print(success ? '✅ 分享处理成功' : '❌ 分享处理失败');
      
      return success;
      
    } catch (e) {
      print('❌ 后台分享处理失败: $e');
      onProgressUpdate?.call('❌ 分享处理失败', '发生异常: $e');
      try {
        await _channel.invokeMethod('finishShare');
      } catch (_) {}
      return false;
    }
  }

  /// 检查是否为分享Intent并处理（旧方法，保持兼容性）
  static Future<bool> handleShareIntentIfExists() async {
    try {
      print('🔍 检查是否为分享Intent...');
      
      // 检查是否为分享Intent
      final bool? isShare = await _channel.invokeMethod('isShareIntent');
      if (isShare != true) {
        print('❌ 不是分享Intent，跳过处理');
        return false;
      }
      
      print('✅ 检测到分享Intent，开始后台处理...');
      
      // 获取分享数据
      final Map<dynamic, dynamic>? shareData = await _channel.invokeMethod('getSharedData');
      if (shareData == null) {
        print('❌ 没有分享数据');
        return false;
      }
      
      print('📥 获取到分享数据: $shareData');
      
      // 后台处理分享
      final success = await _handleShareInBackground(shareData);
      
      print(success ? '✅ 分享处理成功' : '❌ 分享处理失败');
      
      // 🔥 修改：延迟关闭应用，给用户时间看到结果
      if (success) {
        // 成功后1.5秒关闭
        Timer(Duration(milliseconds: 1500), () async {
          try {
            await _channel.invokeMethod('finishShare');
            print('📱 分享完成，应用已关闭');
          } catch (e) {
            print('❌ 关闭应用失败: $e');
          }
        });
      } else {
        // 失败后2秒关闭
        Timer(Duration(seconds: 2), () async {
          try {
            await _channel.invokeMethod('finishShare');
            print('📱 分享失败，应用已关闭');
          } catch (e) {
            print('❌ 关闭应用失败: $e');
          }
        });
      }
      
      return success;
      
    } catch (e) {
      print('❌ 后台分享处理失败: $e');
      try {
        await _channel.invokeMethod('finishShare');
      } catch (_) {}
      return false;
    }
  }
  
  /// 后台处理分享数据
  static Future<bool> _handleShareInBackground(Map<dynamic, dynamic> shareData, {Function(String, String)? onProgressUpdate}) async {
    try {
      // 1. 检查用户登录状态
      onProgressUpdate?.call('验证用户身份...', '检查登录状态');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final serverDeviceData = prefs.getString('server_device_data');
      
      if (token == null || serverDeviceData == null) {
        print('❌ 用户未登录，无法处理分享');
        onProgressUpdate?.call('❌ 用户未登录', '请先登录应用');
        return false;
      }
      
      // 2. 获取当前群组
      onProgressUpdate?.call('获取目标群组...', '检查当前群组设置');
      final currentGroupId = prefs.getString('current_group_id');
      if (currentGroupId == null) {
        print('❌ 没有当前群组，无法处理分享');
        onProgressUpdate?.call('❌ 没有目标群组', '请先选择一个群组');
        return false;
      }
      
      print('📤 准备发送到群组: $currentGroupId');
      onProgressUpdate?.call('准备发送内容...', '目标群组已确认');
      
      // 3. 根据分享类型处理
      final String type = shareData['type'] ?? '';
      
      if (type.startsWith('text/')) {
        // 处理文本分享
        final String? text = shareData['text'];
        if (text != null && text.isNotEmpty) {
          onProgressUpdate?.call('Sending message...', 'Uploading text content');
                      final success = await _sendTextMessage(currentGroupId, text, token);
                      if (success) {
              onProgressUpdate?.call('✅ Text sent successfully!', 'Content sent to group');
            } else {
              onProgressUpdate?.call('❌ Text send failed', 'Please try again later');
            }
          return success;
        }
      } else if (type == 'multiple') {
        // 🔥 新增：处理多个文件的分享
        final List<dynamic>? files = shareData['files'];
        if (files != null && files.isNotEmpty) {
          print('📎 准备发送${files.length}个文件');
          onProgressUpdate?.call('准备发送文件...', '共${files.length}个文件待发送');
          
          bool allSuccess = true;
          int successCount = 0;
          
          for (int i = 0; i < files.length; i++) {
            final file = files[i] as Map<dynamic, dynamic>;
            final String? filePath = file['path'];
            final String? fileName = file['name'];
            String? fileType = file['type'];
            
            // 显示当前文件进度
            onProgressUpdate?.call('正在发送第${i + 1}个文件...', fileName ?? '未知文件名');
            
            // 🔥 修复：如果文件类型检测失败，根据文件扩展名推断类型
            if (fileType == null || fileType.isEmpty) {
              if (fileName != null) {
                final extension = fileName.toLowerCase().split('.').last;
                if (extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'gif' || extension == 'webp') {
                  fileType = 'image/$extension';
                } else if (extension == 'mp4' || extension == 'avi' || extension == 'mov' || extension == 'mkv') {
                  fileType = 'video/$extension';
                } else if (extension == 'mp3' || extension == 'wav' || extension == 'flac') {
                  fileType = 'audio/$extension';
                } else if (extension == 'pdf') {
                  fileType = 'application/pdf';
                } else if (extension == 'doc' || extension == 'docx') {
                  fileType = 'application/msword';
                } else if (extension == 'xls' || extension == 'xlsx') {
                  fileType = 'application/vnd.ms-excel';
                } else {
                  fileType = 'application/octet-stream';
                }
                print('🔧 根据扩展名推断文件类型: $fileName -> $fileType');
              } else {
                fileType = 'application/octet-stream';
              }
            }
            
            if (filePath != null && fileName != null && fileType != null) {
              print('📎 开始发送第${i + 1}/${files.length}个文件: $fileName');
              print('📎 文件路径: $filePath');
              print('📎 文件类型: $fileType');
              
              // 发送前先验证文件是否存在
              final file = File(filePath);
              if (!file.existsSync()) {
                print('❌ 第${i + 1}个文件不存在: $filePath');
                allSuccess = false;
                onProgressUpdate?.call('第${i + 1}个文件不存在', '$fileName 文件路径无效');
                continue;
              }
              
              // 显示文件大小信息
              final fileSize = file.lengthSync();
              print('📎 文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
              onProgressUpdate?.call('发送第${i + 1}个文件 (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)', fileName);
              
              // 发送文件，增加重试机制
              bool success = false;
              int retryCount = 0;
              const maxRetries = 3;
              
              while (!success && retryCount < maxRetries) {
                if (retryCount > 0) {
                  print('🔄 重试发送第${i + 1}个文件，第${retryCount}次重试');
                  onProgressUpdate?.call('重试发送第${i + 1}个文件', '第${retryCount}次重试 - $fileName');
                  // 重试前等待更长时间
                  await Future.delayed(Duration(seconds: 2));
                }
                
                try {
                  success = await _sendFileMessage(currentGroupId, filePath, fileName, fileType, token);
                  
                  if (success) {
                    print('✅ 第${i + 1}个文件发送成功: $fileName');
                    successCount++;
                    onProgressUpdate?.call('✅ 第${i + 1}个文件发送成功', '已完成 $successCount/${files.length} 个文件');
                    
                    // 发送成功后等待更长时间，确保服务器完全处理完毕
                    if (i < files.length - 1) {
                      print('⏳ 等待服务器处理完成...');
                      onProgressUpdate?.call('等待服务器处理...', '确保文件完全上传');
                      await Future.delayed(Duration(seconds: 3)); // 增加到3秒
                    }
                  } else {
                    retryCount++;
                    if (retryCount >= maxRetries) {
                      print('❌ 第${i + 1}个文件发送失败，已达最大重试次数: $fileName');
                      allSuccess = false;
                      onProgressUpdate?.call('❌ 第${i + 1}个文件发送失败', '$fileName 已重试${maxRetries}次仍失败');
                    }
                  }
                } catch (e) {
                  retryCount++;
                  print('❌ 发送第${i + 1}个文件时出现异常: $e');
                  if (retryCount >= maxRetries) {
                    allSuccess = false;
                    onProgressUpdate?.call('❌ 第${i + 1}个文件发送异常', '$fileName 发送时出现错误: $e');
                  }
                }
              }
            } else {
              print('❌ 第${i + 1}个文件数据不完整: path=$filePath, name=$fileName, type=$fileType');
              allSuccess = false;
              onProgressUpdate?.call('❌ 第${i + 1}个文件数据异常', '文件信息不完整');
            }
          }
          
          // 显示最终结果
          if (allSuccess) {
            print('✅ 所有${files.length}个文件发送成功');
            onProgressUpdate?.call('✅ 所有文件发送完成！', '共发送了${files.length}个文件到当前群组');
          } else {
            print('⚠️ 部分文件发送失败');
            onProgressUpdate?.call('⚠️ 部分文件发送完成', '成功：$successCount/${files.length}个文件');
          }
          
          return allSuccess;
        } else {
          print('❌ 多文件分享数据为空');
          onProgressUpdate?.call('❌ 没有文件可发送', '分享数据为空');
          return false;
        }
      } else if (type.startsWith('image/') || type.startsWith('video/') || 
                 type.startsWith('audio/') || type.startsWith('application/')) {
        // 处理单个文件分享
        final String? filePath = shareData['path'];
        final String? fileName = shareData['name'];
        if (filePath != null && fileName != null) {
          onProgressUpdate?.call('发送文件...', fileName);
          final success = await _sendFileMessage(currentGroupId, filePath, fileName, type, token);
          if (success) {
            onProgressUpdate?.call('✅ 文件发送成功！', '$fileName 已发送到群组');
          } else {
            onProgressUpdate?.call('❌ 文件发送失败', '$fileName 上传失败');
          }
          return success;
        }
      }
      
      print('❌ 不支持的分享类型: $type');
      onProgressUpdate?.call('❌ 不支持的分享类型', '无法处理此类型的内容');
      return false;
      
    } catch (e) {
      print('❌ 后台处理分享数据失败: $e');
      return false;
    }
  }
  
  /// 发送文本消息
  static Future<bool> _sendTextMessage(String groupId, String text, String token) async {
    try {
      print('📝 发送文本消息: ${text.length > 50 ? text.substring(0, 50) + '...' : text}');
      
      final response = await http.post(
        Uri.parse('https://sendtomyself-api-adecumh2za-uc.a.run.app/api/messages/group/$groupId/text'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': text}),
      ).timeout(Duration(seconds: 10));
      
      print('📝 文本消息发送响应: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔥 新增：将分享的文本保存为本地消息
        try {
          await _saveSharedTextAsLocalMessage(groupId, text, response.body);
        } catch (e) {
          print('⚠️ 保存分享文本为本地消息失败: $e');
          // 不影响分享成功的返回结果
        }
        return true;
      } else {
        return false;
      }
      
    } catch (e) {
      print('❌ 发送文本消息失败: $e');
      return false;
    }
  }
  
  /// 发送文件消息
  static Future<bool> _sendFileMessage(String groupId, String filePath, 
                                      String fileName, String fileType, String token) async {
    try {
      print('📎 开始发送文件消息: $fileName');
      print('📎 目标群组: $groupId');
      print('📎 文件路径: $filePath');
      print('📎 MIME类型: $fileType');
      
      final file = File(filePath);
      if (!file.existsSync()) {
        print('❌ 文件不存在: $filePath');
        return false;
      }
      
      final fileSize = file.lengthSync();
      print('📎 文件大小: $fileSize bytes');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://sendtomyself-api-adecumh2za-uc.a.run.app/api/messages/group/$groupId/file'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      // 添加文件
      final multipartFile = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(multipartFile);
      print('📎 添加文件到请求: ${multipartFile.filename}, 大小: ${multipartFile.length}');
      
      // 添加字段
      final processedFileType = _getFileTypeFromMimeType(fileType);
      request.fields['fileName'] = fileName;
      request.fields['fileType'] = processedFileType;
      
      print('📎 请求字段: fileName=$fileName, fileType=$processedFileType');
      print('📎 开始上传文件...');
      
      // 增加超时时间，大文件需要更长时间
      final timeout = fileSize > 10 * 1024 * 1024 ? Duration(minutes: 5) : Duration(seconds: 60);
      final response = await request.send().timeout(timeout);
      
      print('📎 文件上传完成，响应状态码: ${response.statusCode}');
      
      // 读取响应内容以获取更多错误信息
      final responseBody = await response.stream.bytesToString();
      print('📎 响应内容: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ 文件发送成功: $fileName');
        
        // 🔥 新增：将分享的文件保存为本地消息
        try {
          await _saveSharedFileAsLocalMessage(groupId, fileName, filePath, fileType, responseBody);
        } catch (e) {
          print('⚠️ 保存分享文件为本地消息失败: $e');
          // 不影响分享成功的返回结果
        }
        
        return true;
      } else {
        print('❌ 文件发送失败，状态码: ${response.statusCode}, 响应: $responseBody');
        return false;
      }
      
    } catch (e) {
      print('❌ 发送文件消息失败: $e');
      if (e.toString().contains('TimeoutException')) {
        print('❌ 上传超时，可能是文件太大或网络不稳定');
      }
      return false;
    }
  }
  
  /// 从MIME类型获取文件类型
  static String _getFileTypeFromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.startsWith('text/')) return 'document';
    if (mimeType.contains('pdf')) return 'document';
    if (mimeType.contains('document') || mimeType.contains('spreadsheet') || 
        mimeType.contains('presentation')) return 'document';
    return 'file';
  }
  
  /// 🔥 新增：将分享的文件保存为本地消息
  static Future<void> _saveSharedFileAsLocalMessage(
    String groupId, 
    String fileName, 
    String filePath, 
    String fileType, 
    String responseBody
  ) async {
    try {
      print('💾 开始保存分享文件为本地消息: $fileName');
      
      // 解析服务器响应以获取消息ID和文件URL
      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(responseBody);
      } catch (e) {
        print('⚠️ 解析服务器响应失败: $e');
        responseData = null;
      }
      
      // 获取当前设备ID
      final prefs = await SharedPreferences.getInstance();
      final serverDeviceData = prefs.getString('server_device_data');
      String? currentDeviceId;
      if (serverDeviceData != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(serverDeviceData);
          currentDeviceId = data['id'];
        } catch (e) {
          print('解析设备ID失败: $e');
        }
      }
      
      // 构建本地消息对象
      final localMessage = {
        'id': responseData?['id'] ?? 'shared_${DateTime.now().millisecondsSinceEpoch}',
        'text': '',
        'fileType': _getFileTypeFromMimeType(fileType),
        'fileName': fileName,
        'fileUrl': responseData?['fileUrl'],
        'fileSize': responseData?['fileSize'] ?? File(filePath).lengthSync(),
        'filePath': filePath, // 保存本地文件路径
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'isMe': true,
        'status': 'sent',
        'sourceDeviceId': currentDeviceId,
        'isSharedFile': true, // 标记为分享的文件
      };
      
      // 获取群组对话ID
      final conversationId = 'group_$groupId';
      
      // 加载现有消息
      final localStorage = LocalStorageService();
      final existingMessages = await localStorage.loadChatMessages(conversationId);
      
      // 检查是否已存在相同的消息（避免重复）
      final messageId = localMessage['id'].toString();
      final isDuplicate = existingMessages.any((msg) => msg['id'] == messageId);
      
      if (!isDuplicate) {
        // 添加新消息到列表
        existingMessages.add(localMessage);
        
        // 保存更新后的消息列表
        await localStorage.saveChatMessages(conversationId, existingMessages);
        
        print('💾 分享文件已保存为本地消息: $fileName (ID: $messageId)');
      } else {
        print('💾 分享文件消息已存在，跳过保存: $fileName');
      }
      
         } catch (e) {
       print('❌ 保存分享文件为本地消息失败: $e');
       // 不抛出异常，避免影响分享流程
     }
   }
   
   /// 🔥 新增：将分享的文本保存为本地消息
   static Future<void> _saveSharedTextAsLocalMessage(
     String groupId, 
     String text, 
     String responseBody
   ) async {
     try {
       print('💾 开始保存分享文本为本地消息: ${text.length > 50 ? text.substring(0, 50) + '...' : text}');
       
       // 解析服务器响应以获取消息ID
       Map<String, dynamic>? responseData;
       try {
         responseData = jsonDecode(responseBody);
       } catch (e) {
         print('⚠️ 解析服务器响应失败: $e');
         responseData = null;
       }
       
       // 获取当前设备ID
       final prefs = await SharedPreferences.getInstance();
       final serverDeviceData = prefs.getString('server_device_data');
       String? currentDeviceId;
       if (serverDeviceData != null) {
         try {
           final Map<String, dynamic> data = jsonDecode(serverDeviceData);
           currentDeviceId = data['id'];
         } catch (e) {
           print('解析设备ID失败: $e');
         }
       }
       
       // 构建本地消息对象
       final localMessage = {
         'id': responseData?['id'] ?? 'shared_text_${DateTime.now().millisecondsSinceEpoch}',
         'text': text,
         'fileType': null,
         'fileName': null,
         'fileUrl': null,
         'fileSize': null,
         'timestamp': DateTime.now().toUtc().toIso8601String(),
         'isMe': true,
         'status': 'sent',
         'sourceDeviceId': currentDeviceId,
         'isSharedText': true, // 标记为分享的文本
       };
       
       // 获取群组对话ID
       final conversationId = 'group_$groupId';
       
       // 加载现有消息
       final localStorage = LocalStorageService();
       final existingMessages = await localStorage.loadChatMessages(conversationId);
       
       // 检查是否已存在相同的消息（避免重复）
       final messageId = localMessage['id'].toString();
       final isDuplicate = existingMessages.any((msg) => msg['id'] == messageId);
       
       if (!isDuplicate) {
         // 添加新消息到列表
         existingMessages.add(localMessage);
         
         // 保存更新后的消息列表
         await localStorage.saveChatMessages(conversationId, existingMessages);
         
         print('💾 分享文本已保存为本地消息: (ID: $messageId)');
       } else {
         print('💾 分享文本消息已存在，跳过保存');
       }
       
     } catch (e) {
       print('❌ 保存分享文本为本地消息失败: $e');
       // 不抛出异常，避免影响分享流程
     }
   }
} 