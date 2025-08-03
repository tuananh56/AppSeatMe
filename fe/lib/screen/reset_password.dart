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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _email;
  String? _otpFromOtpPage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
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

    // 🔥 Kiểm tra mật khẩu mạnh
    if (newPassword.length < 6) {
      _showMessage("❗ Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      _showMessage("❗ Mật khẩu phải chứa ít nhất 1 chữ in hoa (A-Z)");
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
      _showMessage("❗ Mật khẩu phải chứa ít nhất 1 chữ thường (a-z)");
      return;
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(newPassword)) {
      _showMessage("❗ Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt");
      return;
    }

    // 🔑 Kiểm tra mật khẩu xác nhận
    if (newPassword != confirmPassword) {
      _showMessage("❗ Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.228.138:5000/api/auth/reset-password"),
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
        labelStyle: const TextStyle(color: Colors.red),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.red,
          ),
          onPressed: toggleObscure,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        // Cho focusedBorder trùng với enabledBorder để không nổi bật khi focus
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      cursorColor: Colors.red,
      style: const TextStyle(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // ✅ Canh giữa tiêu đề
        title: const Text(
          "Đặt lại mật khẩu",
          style: TextStyle(color: Colors.white), // ✅ Màu trắng
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
        backgroundColor: Colors.transparent, // ✅ Gradient sẽ hiển thị đúng
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildLogo(), // Thêm logo vào đầu
            const SizedBox(height: 30),
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
              toggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Xác nhận",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
