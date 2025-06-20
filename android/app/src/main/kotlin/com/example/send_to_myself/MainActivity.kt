package com.example.send_to_myself

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.send_to_myself/share"
    private var sharedData: Map<String, Any?>? = null
    private var isShareIntent: Boolean = false
    private var shareProcessed: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedData" -> {
                    android.util.Log.d("MainActivity", "Flutter请求分享数据: $sharedData")
                    result.success(sharedData)
                    // 标记分享已处理
                    shareProcessed = true
                    // 🔥 修复：不再自动关闭应用，等待Flutter发送完成信号
                    // 延迟清除数据，给Flutter足够时间处理
                    Handler(Looper.getMainLooper()).postDelayed({
                        android.util.Log.d("MainActivity", "清除分享数据")
                        sharedData = null
                    }, 5000) // 5秒后清除
                }
                "clearSharedData" -> {
                    android.util.Log.d("MainActivity", "Flutter请求清除分享数据")
                    sharedData = null
                    shareProcessed = true
                    result.success(true)
                    // 如果是分享Intent，立即关闭应用
                    if (isShareIntent) {
                        Handler(Looper.getMainLooper()).postDelayed({
                            finish()
                        }, 1000) // 1秒后关闭
                    }
                }
                "isShareIntent" -> {
                    result.success(isShareIntent)
                }
                "finishShare" -> {
                    android.util.Log.d("MainActivity", "Flutter请求完成分享")
                    if (isShareIntent) {
                        finish()
                    }
                    result.success(true)
                }
                "getDeviceId" -> {
                    // 获取设备ID（可以使用Android ID或生成UUID）
                    val deviceId = android.provider.Settings.Secure.getString(
                        contentResolver,
                        android.provider.Settings.Secure.ANDROID_ID
                    )
                    result.success(deviceId)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d("MainActivity", "onCreate - 检查Intent")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        android.util.Log.d("MainActivity", "onNewIntent - 收到新Intent")
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        android.util.Log.d("MainActivity", "handleIntent - Intent action: ${intent?.action}")
        when (intent?.action) {
            Intent.ACTION_SEND -> {
                isShareIntent = true
                android.util.Log.d("MainActivity", "处理单个分享")
                handleSingleShare(intent)
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                isShareIntent = true
                android.util.Log.d("MainActivity", "处理多个分享")
                handleMultipleShare(intent)
            }
            else -> {
                isShareIntent = false
                android.util.Log.d("MainActivity", "普通应用启动")
            }
        }
    }

    private fun handleSingleShare(intent: Intent) {
        try {
            val type = intent.type
            if (type != null) {
                when {
                    type.startsWith("text/") -> {
                        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                        val sharedSubject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                        val text = if (sharedSubject != null && sharedText != null) {
                            "$sharedSubject\n$sharedText"
                        } else {
                            sharedText ?: sharedSubject ?: ""
                        }
                        
                        if (text.isNotEmpty()) {
                            sharedData = mapOf(
                                "type" to type,
                                "text" to text
                            )
                        }
                    }
                    type.startsWith("image/") || type.startsWith("video/") || type.startsWith("audio/") || type.startsWith("application/") -> {
                        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                        if (uri != null) {
                            val filePath = getRealPathFromUri(uri)
                            val fileName = getFileNameFromUri(uri)
                            
                            if (filePath != null) {
                                sharedData = mapOf(
                                    "type" to type,
                                    "path" to filePath,
                                    "name" to fileName
                                )
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "处理单个分享失败", e)
        }
    }

    private fun handleMultipleShare(intent: Intent) {
        try {
            val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
            if (uris != null && uris.isNotEmpty()) {
                val files = mutableListOf<Map<String, String?>>()
                
                android.util.Log.d("MainActivity", "处理${uris.size}个文件的分享")
                
                for ((index, uri) in uris.withIndex()) {
                    android.util.Log.d("MainActivity", "处理第${index + 1}个文件: $uri")
                    
                    val filePath = getRealPathFromUri(uri)
                    val fileName = getFileNameFromUri(uri)
                    val fileType = getFileTypeFromUri(uri) // 获取每个文件的具体类型
                    
                    android.util.Log.d("MainActivity", "文件${index + 1}: path=$filePath, name=$fileName, type=$fileType")
                    
                    if (filePath != null && fileName != null) {
                        files.add(mapOf(
                            "path" to filePath,
                            "name" to fileName,
                            "type" to fileType
                        ))
                    } else {
                        android.util.Log.w("MainActivity", "文件${index + 1}数据不完整，跳过")
                    }
                }
                
                if (files.isNotEmpty()) {
                    sharedData = mapOf(
                        "type" to "multiple",
                        "files" to files
                    )
                    android.util.Log.d("MainActivity", "多文件分享数据创建成功，共${files.size}个文件")
                } else {
                    android.util.Log.w("MainActivity", "没有有效的文件可以分享")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "处理多个分享失败", e)
        }
    }
    
    private fun getFileTypeFromUri(uri: Uri): String? {
        return try {
            // 首先尝试从ContentResolver获取MIME类型
            val mimeType = contentResolver.getType(uri)
            if (mimeType != null) {
                android.util.Log.d("MainActivity", "从ContentResolver获取到MIME类型: $mimeType")
                return mimeType
            }
            
            // 如果没有获取到，根据文件扩展名推断
            val fileName = getFileNameFromUri(uri)
            if (fileName != null) {
                val extension = fileName.substringAfterLast('.', "").lowercase()
                val inferredType = when (extension) {
                    "jpg", "jpeg" -> "image/jpeg"
                    "png" -> "image/png"
                    "gif" -> "image/gif"
                    "webp" -> "image/webp"
                    "mp4" -> "video/mp4"
                    "avi" -> "video/avi"
                    "mov" -> "video/quicktime"
                    "mkv" -> "video/x-matroska"
                    "mp3" -> "audio/mpeg"
                    "wav" -> "audio/wav"
                    "flac" -> "audio/flac"
                    "pdf" -> "application/pdf"
                    "doc" -> "application/msword"
                    "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                    "xls" -> "application/vnd.ms-excel"
                    "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                    "txt" -> "text/plain"
                    else -> "application/octet-stream"
                }
                android.util.Log.d("MainActivity", "根据扩展名推断MIME类型: $extension -> $inferredType")
                return inferredType
            }
            
            return "application/octet-stream"
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "获取文件类型失败", e)
            return "application/octet-stream"
        }
    }

    private fun getRealPathFromUri(uri: Uri): String? {
        return try {
            when (uri.scheme) {
                "file" -> uri.path
                "content" -> {
                    val cursor = contentResolver.query(uri, null, null, null, null)
                    cursor?.use {
                        if (it.moveToFirst()) {
                            val columnIndex = it.getColumnIndex(android.provider.MediaStore.Images.Media.DATA)
                            if (columnIndex != -1) {
                                return it.getString(columnIndex)
                            }
                        }
                    }
                    
                    // 如果无法获取真实路径，尝试复制文件到临时目录
                    copyUriToTempFile(uri)
                }
                else -> null
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "获取文件路径失败", e)
            null
        }
    }

    private fun copyUriToTempFile(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream != null) {
                val tempDir = File(cacheDir, "shared_temp")
                if (!tempDir.exists()) {
                    tempDir.mkdirs()
                }
                
                val fileName = getFileNameFromUri(uri) ?: "shared_file_${System.currentTimeMillis()}"
                val tempFile = File(tempDir, fileName)
                
                tempFile.outputStream().use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
                
                tempFile.absolutePath
            } else {
                null
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "复制文件失败", e)
            null
        }
    }

    private fun getFileNameFromUri(uri: Uri): String? {
        return try {
            when (uri.scheme) {
                "file" -> File(uri.path ?: "").name
                "content" -> {
                    val cursor = contentResolver.query(uri, null, null, null, null)
                    cursor?.use {
                        if (it.moveToFirst()) {
                            val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                            if (nameIndex != -1) {
                                return it.getString(nameIndex)
                            }
                        }
                    }
                    null
                }
                else -> null
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "获取文件名失败", e)
            null
        }
    }
}
