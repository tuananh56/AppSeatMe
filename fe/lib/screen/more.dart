import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 16),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                "Thêm",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 🔻 Nội dung còn lại
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSectionTitle("Giới thiệu"),
                  _buildListTile(
                    Icons.local_parking,
                    "Tổng quan về nền tảng SeatMe",
                  ),
                  _buildListTile(Icons.description, "Hướng dẫn đặt chỗ"),
                  _buildListTile(
                    Icons.chat_bubble_outline,
                    "Câu hỏi thường gặp khi đặt chỗ",
                  ),
                  const SizedBox(height: 10),
                  _buildSectionTitle("Điều khoản và chính sách"),
                  _buildListTile(Icons.gavel, "Quy chế hoạt động"),
                  _buildListTile(Icons.block, "Điều khoản sử dụng"),
                  _buildListTile(Icons.lock_outline, "Chính sách bảo mật"),
                  _buildListTile(Icons.group, "Điều khoản với Đối tác"),
                  _buildSectionTitle("Hỗ trợ"),
                  _buildListTile(
                    Icons.notifications_none,
                    "Trung tâm hỗ trợ đối tác",
                  ),
                  _buildListTile(
                    Icons.description,
                    "Hướng dẫn nhà hàng hợp tác",
                  ),
                  _buildListTile(Icons.handshake, "Nhà hàng đăng ký hợp tác"),
                  _buildListTile(
                    Icons.account_balance_wallet,
                    "Liên hệ đầu tư và hợp tác",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading: Icon(icon),
            title: Text(title, style: const TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
        ),
        const Divider(),
      ],
    );
  }
}
