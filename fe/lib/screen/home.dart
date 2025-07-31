import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_dat_ban/screen/account.dart';
import 'package:app_dat_ban/screen/nearyou.dart';
import 'package:app_dat_ban/screen/search.dart';
import 'package:app_dat_ban/screen/detailchinhanh.dart';
//import 'package:app_dat_ban/screen/detail/alluudai.dart';
import 'package:app_dat_ban/screen/detail/allchinhanh.dart';
import 'package:app_dat_ban/screen/more.dart';
import 'package:app_dat_ban/screen/admin.dart' as admin;

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  List<Widget> _buildPages() {
    return [
      HomeContent(user: _user),
      const NearYouPage(),
      const SearchPage(),
      const AccountPage(),
      (_user != null && _user!['role'] == 'admin')
          ? const admin.AdminPage()
          : MorePage(), // ❌ không có dấu const vì điều kiện là runtime
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPages()[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.location_pin),
              label: 'Gần bạn',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Tài khoản',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings),
              label: (_user != null && _user!['role'] == 'admin')
                  ? 'Quản trị'
                  : 'Thông tin',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Map<String, dynamic>? user;
  const HomeContent({super.key, this.user});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _deals = [];
  bool _isLoadingBranches = true;
  bool _isLoadingDeals = true;

  @override
  void initState() {
    super.initState();
    fetchBranches();
    fetchDeals();
  }

  Future<void> fetchBranches() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.126.138:5000/api/branches'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _branches = data.cast<Map<String, dynamic>>();
          _isLoadingBranches = false;
        });
      } else {
        throw Exception('Lỗi tải dữ liệu chi nhánh');
      }
    } catch (e) {
      print('❌ Lỗi kết nối API (branches): $e');
      setState(() {
        _isLoadingBranches = false;
      });
    }
  }

  Future<void> fetchDeals() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.126.138:5000/api/deals'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _deals = data.cast<Map<String, dynamic>>();
          _isLoadingDeals = false;
        });
      } else {
        throw Exception('Lỗi tải ưu đãi');
      }
    } catch (e) {
      print('❌ Lỗi kết nối API (deals): $e');
      setState(() {
        _isLoadingDeals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        title: Row(
          children: const [
            Icon(Icons.location_on, color: Colors.red, size: 24),
            SizedBox(width: 4),
            Text(
              'TP. Hồ Chí Minh',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.red),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Chi nhánh nhà hàng'),
            const SizedBox(height: 16),
            _buildBranchList(),
            const SizedBox(height: 24),
            _buildSectionHeader('Ưu đãi cực HOT'),
            const SizedBox(height: 16),
            _buildDealsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (title.toLowerCase().contains('chi nhánh')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllChiNhanhPage(
                      initialTabIndex: 0,
                    ), // ✔ chỉ hiển thị chi nhánh
                  ),
                );
              } else if (title.toLowerCase().contains('ưu đãi')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AllChiNhanhPage(
                      initialTabIndex: 1,
                    ), // ✔ sang ưu đãi riêng
                  ),
                );
              }
            },
            child: Text(
              'Xem tất cả',
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchList() {
    if (_isLoadingBranches) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        itemCount: _branches.length,
        itemBuilder: (context, index) {
          final branch = _branches[index];
          return _buildBranchCard(
            branch
          );
        },
      ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> branch) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailChiNhanhPage(
              id: branch['_id'],
              imagePath: 'assets/imgChiNhanh/${branch['image']}',
              name: branch['name'],
              address: branch['address'],
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'assets/imgChiNhanh/${branch['image']}',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              branch['name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              branch['address'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Đặt bàn giữ chỗ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsList() {
    if (_isLoadingDeals) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _deals.length,
      itemBuilder: (context, index) {
        final deal = _deals[index];
        return _buildDealCard(
          deal['image'] ?? '',
          deal['title'] ?? '',
          deal['expiry'] ?? '',
        );
      },
    );
  }

  Widget _buildDealCard(String imageFileName, String title, String expiry) {
    return InkWell(
      onTap: () => debugPrint('Đã nhấn vào $title'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'assets/imgUuDai/$imageFileName',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thời gian áp dụng: $expiry',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
