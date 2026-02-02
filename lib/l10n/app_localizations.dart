import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'myProfile': 'My Profile',
      'general': 'General',
      'notifications': 'Notifications',
      'language': 'Language',
      'supportLegal': 'Support & Legal',
      'termsOfUse': 'Terms of Use',
      'privacyPolicy': 'Privacy Policy',
      'faq': 'FAQ',
      'aboutApp': 'About App',
      'logOut': 'Log Out',
      'logoutConfirmationTitle': 'Log out',
      'logoutConfirmationMessage': 'Are you sure you want to log out of your account?',
      'cancel': 'Cancel',
      'selectOrganization': 'Select Organization',
      'noOrgSelected': 'No Organization Selected',
      'selectOrgPrompt': 'Please go to your Profile to select an organization and view available rooms.',
      'search': 'Search...',
      'filterRooms': 'Filter Rooms',
      'filtersActive': 'Filters active',
      'clearAll': 'Clear all',
      'noRoomsFound': 'No rooms found',
      'available': 'Available',
      'occupied': 'Occupied',
      'reserveRoom': 'Reserve This Room',
      'currentlyUnavailable': 'Currently Unavailable',
      'info': 'Info',
      'building': 'Building',
      'floor': 'Floor',
      'capacity': 'Capacity',
      'availability': 'Availability',
      'bookingRules': 'Booking Rules',
      'minDuration': 'Min Duration',
      'maxDuration': 'Max Duration',
      'advanceBooking': 'Advance Booking',
      'approvalRequired': 'Approval Required',
      'features': 'Features & Amenities',
      'seeMore': 'See More',
      'seeLess': 'See Less',
      'live': 'LIVE',
      'today': 'Today',
      'yes': 'Yes',
      'no': 'No',
      'mins': 'mins',
      'hour': 'Hour',
      'hours': 'Hours',
      'days': 'days',
      'reset': 'Reset',
      'done': 'Done',
      'type': 'Type',
      'home': 'Home',
      'booked': 'Booked',
      'rooms': 'Rooms',
      'profile': 'Profile',
      'login': 'Login',
      'register': 'Register',
      'welcomeBack': 'Welcome back! Glad to see you again',
      'email': 'Email',
      'password': 'Password',
      'orLoginWith': 'Or Login with',
      'google': 'Google',
      'dontHaveAccount': 'Don’t have an account? ',
      'registerNow': 'Register Now',
      'helloRegister': 'Hello! Register to get started',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'confirmPassword': 'Confirm password',
      'orRegisterWith': 'Or Register with',
      'alreadyHaveAccount': 'Already have an account? ',
      'loginNow': 'Login Now',
      'allFieldsRequired': 'All fields are required',
      'passwordsDoNotMatch': 'Passwords do not match',
      'registrationFailed': 'Registration failed',
      'loginFailed': 'Login failed',
      'somethingWentWrong': 'Something went wrong. Please try again.',
      'googleSignInFailed': 'Google sign-in failed. Please try again.',
    },
    'ja': {
      'myProfile': 'プロフィール',
      'general': '一般',
      'notifications': '通知',
      'language': '言語',
      'supportLegal': 'サポート・法的情報',
      'termsOfUse': '利用規約',
      'privacyPolicy': 'プライバシーポリシー',
      'faq': 'よくある質問',
      'aboutApp': 'アプリについて',
      'logOut': 'ログアウト',
      'logoutConfirmationTitle': 'ログアウト',
      'logoutConfirmationMessage': 'ログアウトしてもよろしいですか？',
      'cancel': 'キャンセル',
      'selectOrganization': '組織を選択',
      'noOrgSelected': '組織が選択されていません',
      'selectOrgPrompt': 'プロフィール画面で組織を選択してください。',
      'search': '検索...',
      'filterRooms': '部屋をフィルター',
      'filtersActive': 'フィルター適用中',
      'clearAll': 'すべてクリア',
      'noRoomsFound': '部屋が見つかりません',
      'available': '利用可能',
      'occupied': '使用中',
      'reserveRoom': 'この部屋を予約',
      'currentlyUnavailable': '現在利用不可',
      'info': '情報',
      'building': '建物',
      'floor': '階',
      'capacity': '収容人数',
      'availability': '利用可能時間',
      'bookingRules': '予約ルール',
      'minDuration': '最小時間',
      'maxDuration': '最大時間',
      'advanceBooking': '事前予約',
      'approvalRequired': '承認が必要',
      'features': '設備・アメニティ',
      'seeMore': 'もっと見る',
      'seeLess': '閉じる',
      'live': 'ライブ',
      'today': '今日',
      'yes': 'はい',
      'no': 'いいえ',
      'mins': '分',
      'hour': '時間',
      'hours': '時間',
      'days': '日',
      'reset': 'リセット',
      'done': '完了',
      'type': 'タイプ',
      'home': 'ホーム',
      'booked': '予約済み',
      'rooms': '部屋',
      'profile': 'プロフィール',
      'login': 'ログイン',
      'register': '登録',
      'welcomeBack': 'お帰りなさい！',
      'email': 'メールアドレス',
      'password': 'パスワード',
      'orLoginWith': 'または、以下でログイン',
      'google': 'Google',
      'dontHaveAccount': 'アカウントをお持ちでないですか？ ',
      'registerNow': '今すぐ登録',
      'helloRegister': 'こんにちは！登録して始めましょう',
      'firstName': '名',
      'lastName': '姓',
      'confirmPassword': 'パスワード（確認）',
      'orRegisterWith': 'または、以下で登録',
      'alreadyHaveAccount': 'すでにアカウントをお持ちですか？ ',
      'loginNow': '今すぐログイン',
      'allFieldsRequired': 'すべてのフィールドを入力してください',
      'passwordsDoNotMatch': 'パスワードが一致しません',
      'registrationFailed': '登録に失敗しました',
      'loginFailed': 'ログインに失敗しました',
      'somethingWentWrong': 'エラーが発生しました。もう一度お試しください。',
      'googleSignInFailed': 'Googleログインに失敗しました。もう一度お試しください。',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
