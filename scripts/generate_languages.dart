#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

// 前30种主要语言的语言代码和名称
const Map<String, String> languages = {
  'es': 'Spanish', // 西班牙语
  'hi': 'Hindi', // 印地语
  'ar': 'Arabic', // 阿拉伯语
  'pt': 'Portuguese', // 葡萄牙语
  'bn': 'Bengali', // 孟加拉语
  'ru': 'Russian', // 俄语
  'ja': 'Japanese', // 日语
  'de': 'German', // 德语
  'ko': 'Korean', // 韩语
  'fr': 'French', // 法语
  'tr': 'Turkish', // 土耳其语
  'vi': 'Vietnamese', // 越南语
  'it': 'Italian', // 意大利语
  'th': 'Thai', // 泰语
  'pl': 'Polish', // 波兰语
  'uk': 'Ukrainian', // 乌克兰语
  'nl': 'Dutch', // 荷兰语
  'sv': 'Swedish', // 瑞典语
  'da': 'Danish', // 丹麦语
  'no': 'Norwegian', // 挪威语
  'fi': 'Finnish', // 芬兰语
  'he': 'Hebrew', // 希伯来语
  'id': 'Indonesian', // 印尼语
  'ms': 'Malay', // 马来语
  'cs': 'Czech', // 捷克语
  'hu': 'Hungarian', // 匈牙利语
  'ro': 'Romanian', // 罗马尼亚语
  'sk': 'Slovak', // 斯洛伐克语
};

// 基础翻译映射（部分重要词汇）
const Map<String, Map<String, String>> translations = {
  'es': { 
    'appTitle': 'Enviar a Mí Mismo',
    'confirm': 'Confirmar', 'cancel': 'Cancelar', 'delete': 'Eliminar',
    'home': 'Inicio', 'messages': 'Mensajes', 'files': 'Archivos',
    'settings': 'Configuración', 'login': 'Iniciar Sesión'
  },
  'hi': { 
    'appTitle': 'खुद को भेजें',
    'confirm': 'पुष्टि करें', 'cancel': 'रद्द करें', 'delete': 'हटाएं',
    'home': 'होम', 'messages': 'संदेश', 'files': 'फ़ाइलें',
    'settings': 'सेटिंग्स', 'login': 'लॉगिन'
  },
  'ar': { 
    'appTitle': 'إرسال لنفسي',
    'confirm': 'تأكيد', 'cancel': 'إلغاء', 'delete': 'حذف',
    'home': 'الرئيسية', 'messages': 'الرسائل', 'files': 'الملفات',
    'settings': 'الإعدادات', 'login': 'تسجيل الدخول'
  },
  'pt': { 
    'appTitle': 'Enviar para Mim Mesmo',
    'confirm': 'Confirmar', 'cancel': 'Cancelar', 'delete': 'Excluir',
    'home': 'Início', 'messages': 'Mensagens', 'files': 'Arquivos',
    'settings': 'Configurações', 'login': 'Entrar'
  },
  'ru': { 
    'appTitle': 'Отправить себе',
    'confirm': 'Подтвердить', 'cancel': 'Отмена', 'delete': 'Удалить',
    'home': 'Главная', 'messages': 'Сообщения', 'files': 'Файлы',
    'settings': 'Настройки', 'login': 'Войти'
  },
  'ja': { 
    'appTitle': '自分に送信',
    'confirm': '確認', 'cancel': 'キャンセル', 'delete': '削除',
    'home': 'ホーム', 'messages': 'メッセージ', 'files': 'ファイル',
    'settings': '設定', 'login': 'ログイン'
  },
  'de': { 
    'appTitle': 'An mich senden',
    'confirm': 'Bestätigen', 'cancel': 'Abbrechen', 'delete': 'Löschen',
    'home': 'Start', 'messages': 'Nachrichten', 'files': 'Dateien',
    'settings': 'Einstellungen', 'login': 'Anmelden'
  },
  'ko': { 
    'appTitle': '나에게 보내기',
    'confirm': '확인', 'cancel': '취소', 'delete': '삭제',
    'home': '홈', 'messages': '메시지', 'files': '파일',
    'settings': '설정', 'login': '로그인'
  },
  'fr': { 
    'appTitle': 'Envoyer à moi-même',
    'confirm': 'Confirmer', 'cancel': 'Annuler', 'delete': 'Supprimer',
    'home': 'Accueil', 'messages': 'Messages', 'files': 'Fichiers',
    'settings': 'Paramètres', 'login': 'Connexion'
  },
  'tr': { 
    'appTitle': 'Kendime Gönder',
    'confirm': 'Onayla', 'cancel': 'İptal', 'delete': 'Sil',
    'home': 'Ana Sayfa', 'messages': 'Mesajlar', 'files': 'Dosyalar',
    'settings': 'Ayarlar', 'login': 'Giriş'
  }
};

Future<void> main() async {
  print('🌍 开始生成多语言文件...');

  final l10nDir = Directory('lib/l10n');
  if (!await l10nDir.exists()) {
    await l10nDir.create(recursive: true);
  }

  // 读取英语模板文件
  final enFile = File('lib/l10n/app_en.arb');
  if (!await enFile.exists()) {
    print('❌ 英语模板文件不存在: ${enFile.path}');
    return;
  }

  final String enContent = await enFile.readAsString();
  final Map<String, dynamic> enData = jsonDecode(enContent);

  int count = 0;
  for (final entry in languages.entries) {
    final langCode = entry.key;
    final langName = entry.value;
    
    // 跳过已存在的语言文件
    final langFile = File('lib/l10n/app_$langCode.arb');
    if (await langFile.exists()) {
      print('⚠️  跳过已存在的语言文件: $langCode ($langName)');
      continue;
    }

    print('📝 生成 $langCode ($langName) 语言文件...');

    // 创建新的语言数据
    final Map<String, dynamic> langData = <String, dynamic>{
      '@@locale': langCode,
    };

    // 复制英语模板数据并替换已翻译的部分
    for (final enEntry in enData.entries) {
      final key = enEntry.key;
      final value = enEntry.value;

      if (key.startsWith('@@') || key.startsWith('@')) {
        // 保持元数据
        if (key != '@@locale') {
          langData[key] = value;
        }
      } else {
        // 检查是否有翻译，否则使用英语原文
        if (translations.containsKey(langCode) && 
            translations[langCode]!.containsKey(key)) {
          langData[key] = translations[langCode]![key];
        } else {
          langData[key] = value; // 使用英语作为fallback
        }
      }
    }

    // 写入文件
    final encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(langData);
    await langFile.writeAsString(jsonString);

    count++;
    print('✅ 完成: $langCode ($langName)');
  }

  print('\n🎉 多语言文件生成完成!');
  print('📊 总共生成了 $count 个新语言文件');
  print('🔗 支持的语言总数: ${languages.length + 2} (包括英语和中文)');
} 