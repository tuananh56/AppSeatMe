import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_dat_ban/server/api_service.dart';
import 'package:app_dat_ban/screen/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final phone = _phoneController.text.trim();

    if ([name, email, password, confirmPassword, phone].any((e) => e.isEmpty) ||
        _selectedImage == null) {
      _showMessage('Vui lòng điền đầy đủ thông tin và chọn ảnh đại diện');
      return;
    }

    // ✅ Kiểm tra độ dài mật khẩu
    if (password.length < 6) {
      _showMessage('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    // ✅ Kiểm tra chữ in hoa
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _showMessage('Mật khẩu phải chứa ít nhất 1 chữ in hoa (A-Z)');
      return;
    }

    // ✅ Kiểm tra chữ thường
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      _showMessage('Mật khẩu phải chứa ít nhất 1 chữ thường (a-z)');
      return;
    }

    // ✅ Kiểm tra ký tự đặc biệt
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _showMessage('Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    final error = await ApiService.register(
      name,
      email,
      password,
      _selectedImage!.path,
      phone,
      confirmPassword,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      _showMessage(' Đăng ký thành công', bgColor: Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      _showMessage(error);
    }
  }

  void _showMessage(String message, {Color bgColor = Colors.red}) {
    final icon = bgColor == Colors.green
        ? Icons.check_circle_outline
        : Icons.error_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.red),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.red,
                ),
                onPressed: toggleObscure,
              )
            : Icon(icon, color: Colors.red),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : null,
              child: _selectedImage == null
                  ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _pickImage,
            child: const Text(
              'Chọn ảnh đại diện',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
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

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Đăng ký',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Bạn đã có tài khoản? ",
          style: TextStyle(color: Colors.grey),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildRedBackground(double height) {
    return Container(
      height: height * 0.35,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildRedBackground(screenHeight),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.18),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 40.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 30),
                        _buildInputField(
                          icon: Icons.person,
                          label: 'Họ tên',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          icon: Icons.email,
                          label: 'Email',
                          controller: _emailController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          icon: Icons.lock,
                          label: 'Mật khẩu',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          toggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          icon: Icons.lock_outline,
                          label: 'Xác nhận mật khẩu',
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          toggleObscure: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          icon: Icons.phone,
                          label: 'Số điện thoại',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 30),
                        _buildImagePicker(),
                        const SizedBox(height: 20),
                        _buildRegisterButton(),
                        const SizedBox(height: 30),
                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
