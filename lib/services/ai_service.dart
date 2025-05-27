import 'dart:convert';
import 'package:dio/dio.dart';

class AIService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey = 'YOUR_API_KEY'; // TODO: 从环境变量或配置文件读取
  
  final Dio _dio = Dio();

  AIService() {
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  /// 根据内容生成标题
  Future<String> generateTitle(String content) async {
    if (content.trim().isEmpty) {
      return '未命名记忆';
    }

    // 如果内容较短，直接使用内容作为标题
    if (content.length <= 30) {
      return content.trim();
    }

    // 暂时使用后备方案，避免API调用
    return _generateFallbackTitle(content);

    /* TODO: 启用真实AI调用
    try {
      final response = await _dio.post(_apiUrl, data: {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个专业的内容标题生成助手。请为用户提供的内容生成一个简洁、准确的标题。标题应该：\n'
                      '1. 控制在15个字符以内\n'
                      '2. 概括内容的核心要点\n'
                      '3. 使用中文\n'
                      '4. 不需要添加引号或其他符号\n'
                      '只需要返回标题文本，不需要任何解释。'
          },
          {
            'role': 'user',
            'content': '为以下内容生成标题：\n$content'
          }
        ],
        'max_tokens': 50,
        'temperature': 0.7,
      });

      final generatedTitle = response.data['choices'][0]['message']['content'].toString().trim();
      return generatedTitle.isNotEmpty ? generatedTitle : _generateFallbackTitle(content);
    } catch (e) {
      print('AI标题生成失败: $e');
      return _generateFallbackTitle(content);
    }
    */
  }

  /// 根据内容生成标签
  Future<List<String>> generateTags(String content) async {
    if (content.trim().isEmpty) {
      return [];
    }

    // 暂时使用后备方案，避免API调用
    return _generateFallbackTags(content);

    /* TODO: 启用真实AI调用
    try {
      final response = await _dio.post(_apiUrl, data: {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个智能标签生成助手。请为用户提供的内容生成3-5个相关标签。标签应该：\n'
                      '1. 每个标签2-4个字符\n'
                      '2. 描述内容的主题、类别或关键词\n'
                      '3. 使用中文\n'
                      '4. 用逗号分隔\n'
                      '5. 不要重复\n'
                      '只需要返回标签列表，用逗号分隔，不需要任何解释。'
          },
          {
            'role': 'user',
            'content': '为以下内容生成标签：\n$content'
          }
        ],
        'max_tokens': 100,
        'temperature': 0.8,
      });

      final generatedTags = response.data['choices'][0]['message']['content'].toString().trim();
      if (generatedTags.isNotEmpty) {
        return generatedTags
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty && tag.length <= 10)
            .take(5)
            .toList();
      }
    } catch (e) {
      print('AI标签生成失败: $e');
    }

    return _generateFallbackTags(content);
    */
  }

  /// 后备标题生成方案
  String _generateFallbackTitle(String content) {
    final trimmed = content.trim();
    
    // 取第一句话作为标题
    final firstSentence = trimmed.split(RegExp(r'[。！？\n]')).first.trim();
    if (firstSentence.isNotEmpty && firstSentence.length <= 30) {
      return firstSentence;
    }
    
    // 取前20个字符
    if (trimmed.length <= 20) {
      return trimmed;
    }
    
    return '${trimmed.substring(0, 17)}...';
  }

  /// 后备标签生成方案
  List<String> _generateFallbackTags(String content) {
    final tags = <String>[];
    final text = content.toLowerCase();
    
    // 简单的关键词匹配
    final keywordMap = {
      '工作': ['工作', '会议', '项目', '任务', '同事', '公司', '办公'],
      '学习': ['学习', '课程', '考试', '笔记', '书籍', '知识'],
      '生活': ['购物', '家庭', '朋友', '娱乐', '休闲', '旅行'],
      '健康': ['运动', '健身', '医院', '药物', '健康', '饮食'],
      '财务': ['钱', '支付', '买', '花费', '账单', '投资'],
    };
    
    for (final entry in keywordMap.entries) {
      if (entry.value.any((keyword) => text.contains(keyword))) {
        tags.add(entry.key);
      }
    }
    
    // 如果没有匹配到关键词，添加通用标签
    if (tags.isEmpty) {
      if (content.length > 100) {
        tags.add('详细');
      } else {
        tags.add('简短');
      }
      
      if (content.contains('?') || content.contains('？')) {
        tags.add('疑问');
      }
      
      if (content.contains('!') || content.contains('！')) {
        tags.add('重要');
      }
    }
    
    return tags.take(3).toList();
  }

  /// 优化搜索查询
  Future<List<String>> expandSearchQuery(String query) async {
    if (query.trim().isEmpty) {
      return [query];
    }

    try {
      final response = await _dio.post(_apiUrl, data: {
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个搜索优化助手。请为用户的搜索词生成2-3个相关的同义词或相关词，以改善搜索效果。\n'
                      '要求：\n'
                      '1. 使用中文\n'
                      '2. 每个词用逗号分隔\n'
                      '3. 不要重复原词\n'
                      '4. 只返回词语，不需要解释'
          },
          {
            'role': 'user',
            'content': '为搜索词"$query"生成相关词汇'
          }
        ],
        'max_tokens': 50,
        'temperature': 0.8,
      });

      final related = response.data['choices'][0]['message']['content'].toString().trim();
      if (related.isNotEmpty) {
        final expandedTerms = [query] + related.split(',').map((term) => term.trim()).toList();
        return expandedTerms.take(4).toList();
      }
    } catch (e) {
      print('搜索词扩展失败: $e');
    }

    return [query];
  }
} 