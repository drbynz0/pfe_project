import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'firebase_options.dart';
import '/screens/login_page/login_page.dart';
import '/screens/login_page/reset_password.dart';
import '/screens/login_page/signup_page.dart';
import 'screens/ens_pages/ens_home_page.dart';
import 'screens/etudiant_pages/etud_home_page.dart';
import 'screens/cond_pages/cond_home_page.dart';
import '/services/matiere_service.dart';
import '/providers/locale_provider.dart';
import '/providers/theme_provider.dart';
import '/providers/trip_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MatiereService()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()..loadLocale()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(
      create: (context) => TripProvider(),
      child: const MyApp(),
    ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      locale: localeProvider.locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/homeEns': (context) => const TeacherHomePage(),
        '/homeEtud': (context) => const EtudiantHomePage(),
        '/homeCond': (context) => const CondHomePage(),
        '/signup': (context) => const SignupPage(),
        '/resetPwd': (context) => const ResetPasswordPage(),
      },

    );
  }
}