import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/trainer/trainer_home_screen.dart';
import 'screens/member/member_home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  _initAppLinks();
  runApp(const FitCoachApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _initAppLinks() {
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    _handleIncomingLink(uri);
  });
}

void _handleIncomingLink(Uri uri) {
  final mode = uri.queryParameters['mode'];
  final oobCode = uri.queryParameters['oobCode'];
  if (mode == 'resetPassword' && oobCode != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => ResetPasswordScreen(oobCode: oobCode)),
    );
  }
}

class FitCoachApp extends StatelessWidget {
  const FitCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'FitCoach',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        navigatorKey: navigatorKey,
        home: const _AuthWrapper(),
      ),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, color: AppColors.primary, size: 56),
              SizedBox(height: 24),
              CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    if (auth.currentUser == null) {
      return const LoginScreen();
    }

    if (auth.userRole == 'trainer') {
      return const TrainerHomeScreen();
    }

    return const MemberHomeScreen();
  }
}
