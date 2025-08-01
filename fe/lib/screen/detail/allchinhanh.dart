import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../detailchinhanh.dart';
import 'alluudai.dart';

class AllChiNhanhPage extends StatefulWidget {
  final int initialTabIndex;

  const AllChiNhanhPage({super.key, this.initialTabIndex = 0});

  @override
  State<AllChiNhanhPage> createState() => _AllChiNhanhPageState();
}

class _AllChiNhanhPageState extends State<AllChiNhanhPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);

    // 👇 Lắng nghe để cập nhật UI khi chuyển tab
    _tabController.addListener(() {
      setState(() {});
    });

    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.126.138:5000/api/branches'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _branches = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Lỗi tải chi nhánh');
      }
    } catch (e) {
      print('❌ Lỗi API (branches): $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildTab(String label, int index) {
    final bool isSelected = _tabController.index == index;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.red : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem tất cả', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _tabController.animateTo(0),
                  child: buildTab('Nhà hàng', 0),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _tabController.animateTo(1),
                  child: buildTab('Ưu đãi', 1),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/imgChiNhanh/${branch['image']}',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                      title: Text(branch['name'] ?? ''),
                      subtitle: Text(branch['address'] ?? ''),
                      onTap: () {
                       /*ở đây*/  Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailChiNhanhPage(
                              id: branch['_id'],
                              imagePath: 'assets/imgChiNhanh/${branch['image']}',
                              name: branch['name'] ?? '',
                              address: branch['address'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          const AllUuDaiPage(), // Ưu đãi
        ],
      ),
    );
  }
}
