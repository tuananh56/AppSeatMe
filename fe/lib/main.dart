import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_dat_ban/screen/intro.dart';
import 'package:app_dat_ban/screen/otp_page.dart';
import 'package:app_dat_ban/screen/reset_password.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_logged_in', false); // reset trạng thái đăng nhập

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App đặt bàn',
      debugShowCheckedModeBanner: false,

      locale: const Locale('vi'),
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),

      home: const IntroPage(),

      // ✅ Thêm các tuyến đường
      routes: {
        '/otp': (context) => const OtpPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        
      },
    );
  }
}
