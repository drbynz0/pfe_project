// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `School App`
  String get appTitle {
    return Intl.message('School App', name: 'appTitle', desc: '', args: []);
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Notes`
  String get notes {
    return Intl.message('Notes', name: 'notes', desc: '', args: []);
  }

  /// `Messages`
  String get messages {
    return Intl.message('Messages', name: 'messages', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Modify Profile`
  String get profile {
    return Intl.message('Modify Profile', name: 'profile', desc: '', args: []);
  }

  /// `Change Password`
  String get password {
    return Intl.message(
      'Change Password',
      name: 'password',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Receive Notifications`
  String get notifications {
    return Intl.message(
      'Receive Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Exam Reminders`
  String get examReminders {
    return Intl.message(
      'Exam Reminders',
      name: 'examReminders',
      desc: '',
      args: [],
    );
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message('Dark Mode', name: 'darkMode', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Biometric Authentication`
  String get biometricAuth {
    return Intl.message(
      'Biometric Authentication',
      name: 'biometricAuth',
      desc: '',
      args: [],
    );
  }

  /// `Manage Sessions`
  String get manageSessions {
    return Intl.message(
      'Manage Sessions',
      name: 'manageSessions',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `App Version`
  String get appVersion {
    return Intl.message('App Version', name: 'appVersion', desc: '', args: []);
  }

  /// `Technical Support`
  String get support {
    return Intl.message(
      'Technical Support',
      name: 'support',
      desc: '',
      args: [],
    );
  }

  /// `Class`
  String get classLabel {
    return Intl.message('Class', name: 'classLabel', desc: '', args: []);
  }

  /// `Number of Subjects`
  String get numberOfSubjects {
    return Intl.message(
      'Number of Subjects',
      name: 'numberOfSubjects',
      desc: '',
      args: [],
    );
  }

  /// `Number of Students`
  String get numberOfStudents {
    return Intl.message(
      'Number of Students',
      name: 'numberOfStudents',
      desc: '',
      args: [],
    );
  }

  /// `Class Management`
  String get classManagement {
    return Intl.message(
      'Class Management',
      name: 'classManagement',
      desc: '',
      args: [],
    );
  }

  /// `Class and Student Management`
  String get classAndStudentManagement {
    return Intl.message(
      'Class and Student Management',
      name: 'classAndStudentManagement',
      desc: '',
      args: [],
    );
  }

  /// `Student List by Class`
  String get studentListByClass {
    return Intl.message(
      'Student List by Class',
      name: 'studentListByClass',
      desc: '',
      args: [],
    );
  }

  /// `Bulletin Management`
  String get bulletinManagement {
    return Intl.message(
      'Bulletin Management',
      name: 'bulletinManagement',
      desc: '',
      args: [],
    );
  }

  /// `Student Bulletin`
  String get studentBulletin {
    return Intl.message(
      'Student Bulletin',
      name: 'studentBulletin',
      desc: '',
      args: [],
    );
  }

  /// `Profile & Account`
  String get profileAndAccount {
    return Intl.message(
      'Profile & Account',
      name: 'profileAndAccount',
      desc: '',
      args: [],
    );
  }

  /// `Notifications & Alerts`
  String get notificationsAndAlerts {
    return Intl.message(
      'Notifications & Alerts',
      name: 'notificationsAndAlerts',
      desc: '',
      args: [],
    );
  }

  /// `Display & Accessibility`
  String get displayAndAccessibility {
    return Intl.message(
      'Display & Accessibility',
      name: 'displayAndAccessibility',
      desc: '',
      args: [],
    );
  }

  /// `Security & Privacy`
  String get securityAndPrivacy {
    return Intl.message(
      'Security & Privacy',
      name: 'securityAndPrivacy',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'fr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
