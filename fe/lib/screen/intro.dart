import 'package:app_dat_ban/screen/home.dart';
//import 'package:app_dat_ban/screen/login.dart';
import 'package:flutter/material.dart';
//import 'package:app_dat_ban/screen/home.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    super.initState();
    // Chờ 5 giây rồi chuyển sang trang Home
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 350, height: 350),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
