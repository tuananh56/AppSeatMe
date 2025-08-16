// account.dart
import 'package:app_dat_ban/screen/chat.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_dat_ban/screen/login.dart';
import 'package:app_dat_ban/screen/booking_history.dart';
import 'package:app_dat_ban/screen/like_chua.dart';
//import 'package:app_dat_ban/screen/home.dart';
import 'package:app_dat_ban/screen/edit_profile.dart';
import 'package:app_dat_ban/screen/admin_chat.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _user;
  String? _userImage;

  @override
  void initState() {
    super.initState();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final userData = prefs.getString('user');
    final imageUrl = prefs.getString('userImage');

    if (isLoggedIn && userData != null) {
      setState(() {
        _user = json.decode(userData);
        _userImage = imageUrl;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('userImage');
    await prefs.setBool('is_logged_in', false);

    setState(() {
      _user = null;
      _userImage = null;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.logout, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đăng xuất thành công',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    ).then((_) {
      _loadUserFromPrefs();
    });
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu đăng nhập'),
        content: const Text('Vui lòng đăng nhập để sử dụng chức năng này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Đóng dialog
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              ).then((_) => _loadUserFromPrefs()); // Tải lại sau khi đăng nhập
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  void _goToBookingHistory() {
    final user = _user;
    if (user != null && user['email'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingHistoryPage(userId: user['_id']),
        ),
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _user != null ? _buildLoggedInView() : _buildLoginPrompt();
  }

  Widget _buildLoggedInView() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
            ),
          ),
          child: AppBar(
            title: const Text(
              "Tài khoản",
              style: TextStyle(
                fontWeight: FontWeight.bold, // ✅ Đặt font đậm ở đây
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent, // transparent để lộ gradient
            elevation: 0,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card thông tin người dùng
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          (_userImage != null && _userImage!.isNotEmpty)
                          ? NetworkImage(
                              "http://192.168.228.138:5000$_userImage",
                            )
                          : null,
                      child: (_userImage == null || _userImage!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _user!['name'] ?? 'Không có tên',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!['email'] ?? 'Không có email',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_user != null && _user!['role'] == 'admin')
              _buildMenuTile(
                Icons.admin_panel_settings,
                'Hỗ trợ khách hàng',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminChatScreen()),
                  );
                },
              ),
            // Danh sách chức năng
            if (_user != null && _user!['role'] != 'admin')
              _buildMenuTile(Icons.support_agent, 'Liên hệ hỗ trợ', () {
                if (_user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatPage(user: _user), // 👉 Truyền user sang ChatPage
                    ),
                  );
                } else {
                  _showLoginRequiredDialog(); // Nếu chưa đăng nhập thì yêu cầu đăng nhập
                }
              }),
            _buildMenuTile(Icons.edit, 'Chỉnh sửa thông tin', () {
              if (_user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(user: _user!),
                  ),
                ).then((updatedUser) {
                  if (updatedUser != null) {
                    setState(() {
                      _user = updatedUser; // cập nhật Card ngay lập tức
                    });
                  }
                 // _loadUserFromPrefs();
                });
              }
            }),
            _buildMenuTile(
              Icons.history,
              'Lịch sử đặt bàn',
              _goToBookingHistory,
            ),
            _buildMenuTile(Icons.favorite_border, 'Yêu thích', () {
              if (_user != null && _user!['_id'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LikePage(
                      userId: _user!['_id'],
                    ), // ✅ Mở trực tiếp LikePage
                  ),
                );
              }
            }),
            const Divider(height: 32),
            _buildMenuTile(
              Icons.logout,
              'Đăng xuất',
              _logout,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Text(
                      'Đăng nhập để cải thiện trải nghiệm',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _goToLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 110,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập / Đăng ký',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                _buildMenuItem(Icons.person_outline, 'Thông tin tài khoản', () {
                  if (_user == null) {
                    _showLoginRequiredDialog();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(
                          user: _user!,
                        ), // hoặc userId: _user!['_id']
                      ),
                    );
                  }
                }),
                _buildMenuItem(Icons.history, 'Lịch sử giao dịch', () {
                  if (_user == null) {
                    _showLoginRequiredDialog();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookingHistoryPage(userId: _user!['_id']),
                      ),
                    );
                  }
                }),
                _buildMenuItem(Icons.favorite_border, 'Yêu thích', () {
                  if (_user == null) {
                    _showLoginRequiredDialog();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LikePage(userId: _user!['_id']),
                      ),
                    );
                  }
                }),
                _buildMenuTile(Icons.support_agent, 'Liên hệ hỗ trợ', () {
                  if (_user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          user: _user,
                        ), // 👉 Truyền user sang ChatPage
                      ),
                    );
                  } else {
                    _showLoginRequiredDialog(); // Nếu chưa đăng nhập thì yêu cầu đăng nhập
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.brown),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
