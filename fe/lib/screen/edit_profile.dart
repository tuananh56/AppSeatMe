import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_dat_ban/server/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  final Color primaryColor = Color(0xFFB71C1C); // dark red

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _emailController = TextEditingController(text: widget.user['email']);
    _phoneController = TextEditingController(text: widget.user['phone']);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmNewPasswordController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showMessage('❗ Vui lòng nhập đầy đủ họ tên và số điện thoại');
      return;
    }

    if (newPassword.isNotEmpty && newPassword != confirmPassword) {
      _showMessage('❗ Mật khẩu mới và xác nhận mật khẩu không khớp');
      return;
    }

    setState(() => _isLoading = true);

    final error = await ApiService.updateProfile(
      name: name,
      phone: phone,
      imageFile: _selectedImage,
      currentPassword: currentPassword.isNotEmpty ? currentPassword : null,
      newPassword: newPassword.isNotEmpty ? newPassword : null,
      userId: widget.user['_id'],
    );

    setState(() => _isLoading = false);

    if (error == null) {
      _showMessage('✅ Cập nhật thành công', bgColor: Colors.green);
      Navigator.pop(context);
    } else {
      _showMessage(error);
    }
  }

  void _showMessage(String msg, {Color bgColor = Colors.red}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bgColor));
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.red),
          suffixIcon: Icon(icon, color: Colors.red),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.red),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggleVisibility,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final imageUrl = widget.user['imageUrl'];
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (imageUrl != null
                          ? NetworkImage(imageUrl)
                          : const AssetImage('assets/avatar_placeholder.png'))
                      as ImageProvider,
            child: _selectedImage == null && imageUrl == null
                ? Icon(Icons.add_a_photo, size: 32, color: primaryColor)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickImage,
          child: Text(
            'Thay ảnh đại diện',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Chỉnh sửa hồ sơ'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAvatar(),
            const SizedBox(height: 20),
            _buildField('Họ tên', Icons.person, _nameController),
            _buildField(
              'Email ',
              Icons.email,
              _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildField(
              'Số điện thoại',
              Icons.phone,
              _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const Divider(height: 40),
            _buildPasswordField(
              label: 'Mật khẩu hiện tại ',
              icon: Icons.lock,
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              toggleVisibility: () =>
                  setState(() => _showCurrentPassword = !_showCurrentPassword),
            ),
            _buildPasswordField(
              label: 'Mật khẩu mới',
              icon: Icons.lock_outline,
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              toggleVisibility: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
            ),
            _buildPasswordField(
              label: 'Xác nhận mật khẩu mới',
              icon: Icons.lock_outline,
              controller: _confirmNewPasswordController,
              obscureText: !_showConfirmPassword,
              toggleVisibility: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white, // ✅ Đặt màu chữ ở đây
                          fontWeight: FontWeight.bold,
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
