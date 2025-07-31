import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)!.settings.arguments as String?;
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6 || int.tryParse(otp) == null) {
      _showMessage('❗ Mã OTP không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.126.138:5000/api/auth/verify-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email!.trim(), 'otp': otp}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage("✅ Mã OTP hợp lệ", isError: false);

        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: {'email': _email, 'otp': otp},
        );
      } else {
        _showMessage(data['message'] ?? "Xác minh thất bại");
      }
    } catch (e) {
      _showMessage('Lỗi kết nối: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Xác minh OTP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Nhập mã OTP đã gửi đến \n email của bạn:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Mã OTP',
                labelStyle: const TextStyle(color: Colors.redAccent),
                suffixIcon: const Icon(Icons.lock_clock, color: Colors.redAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
              ),
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: InkWell(
                onTap: _isLoading ? null : _verifyOtp,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Xác minh',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
