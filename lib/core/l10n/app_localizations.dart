import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ko'),
    Locale('en'),
    Locale('ja'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_name': '앱',
      'settings': '설정',
      'premium': '프리미엄',
      'restore_purchases': '구매 복원',
      'cancel': '취소',
      'confirm': '확인',
      'delete': '삭제',
      'save': '저장',
      'loading': '로딩 중...',
      'error': '오류가 발생했습니다',
      'empty_state': '아직 데이터가 없습니다',
      'onboarding_next': '다음',
      'onboarding_skip': '건너뛰기',
      'onboarding_done': '시작하기',
    },
    'en': {
      'app_name': 'App',
      'settings': 'Settings',
      'premium': 'Premium',
      'restore_purchases': 'Restore Purchases',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'save': 'Save',
      'loading': 'Loading...',
      'error': 'An error occurred',
      'empty_state': 'No data yet',
      'onboarding_next': 'Next',
      'onboarding_skip': 'Skip',
      'onboarding_done': 'Get Started',
    },
    'ja': {
      'app_name': 'アプリ',
      'settings': '設定',
      'premium': 'プレミアム',
      'restore_purchases': '購入を復元',
      'cancel': 'キャンセル',
      'confirm': '確認',
      'delete': '削除',
      'save': '保存',
      'loading': '読み込み中...',
      'error': 'エラーが発生しました',
      'empty_state': 'データがありません',
      'onboarding_next': '次へ',
      'onboarding_skip': 'スキップ',
      'onboarding_done': 'はじめる',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ko', 'en', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
