import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('❗ Vui lòng nhập email hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://172.16.217.138:5000/api/auth/send-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage("✅ Mã OTP đã được gửi đến email", isError: false);
        Navigator.pushNamed(context, '/otp', arguments: email);
      } else {
        _showMessage(data['message'] ?? "Gửi mã OTP thất bại");
      }
    } catch (e) {
      _showMessage('❌ Lỗi kết nối đến server: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLogo() {
    return const Column(
      children: [
        Text(
          'SeatMe',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'ĐẶT BÀN ONLINE',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  /*Widget _buildGradientTitle(String text) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Nền trắng
      appBar: AppBar(
        title: const Text(
          "Quên mật khẩu",
          style: TextStyle(
            color: Colors.white, // ✅ Chữ trắng trên app bar
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _buildLogo(),
                const SizedBox(height: 16),
                const Text(
                  'Nhập địa chỉ email của bạn.\nHệ thống sẽ gửi mã OTP \n để đặt lại mật khẩu.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ✅ TextField với màu chữ và viền màu đỏ
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  //style: const TextStyle(color: Colors.red), // ✅ Chữ đỏ
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.red), // ✅ Label màu đỏ
                    suffixIcon: Icon(
                      Icons.email,
                      color: Colors.red,
                    ), // ✅ Icon màu đỏ
                    border: OutlineInputBorder(), // ✅ Dùng viền mặc định
                  ),
                ),

                const SizedBox(height: 30),

                // ✅ Nút gửi OTP với gradient đỏ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Gửi mã OTP',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
