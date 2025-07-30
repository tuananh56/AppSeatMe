import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _email;
  String? _otpFromOtpPage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'];
    _otpFromOtpPage = args?['otp'];
  }

  Future<void> _submit() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final otp = _otpFromOtpPage?.trim();

    if (otp == null || otp.isEmpty) {
      _showMessage("❗ Thiếu mã OTP từ trang trước");
      return;
    }

    if (newPassword.length < 6) {
      _showMessage("❗ Mật khẩu phải từ 6 ký tự");
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage("❗ Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.126.138:5000/api/auth/reset-password"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage("✅ Đổi mật khẩu thành công", isError: false);
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showMessage(data['message'] ?? "Thất bại khi đặt lại mật khẩu");
      }
    } catch (e) {
      _showMessage("Lỗi kết nối: $e");
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleObscure,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đặt lại mật khẩu"),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPasswordField(
              controller: _newPasswordController,
              label: "Mật khẩu mới",
              obscureText: _obscureNew,
              toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: "Xác nhận mật khẩu",
              obscureText: _obscureConfirm,
              toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Xác nhận", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
