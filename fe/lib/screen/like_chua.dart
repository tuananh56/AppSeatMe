import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_dat_ban/screen/detailchinhanh.dart';
import 'package:app_dat_ban/screen/home.dart';
import 'package:app_dat_ban/screen/nearyou.dart';
import 'package:app_dat_ban/screen/search.dart';
import 'package:app_dat_ban/screen/account.dart';

class LikePage extends StatefulWidget {
  final String userId;

  const LikePage({super.key, required this.userId});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  List<dynamic> likedBranches = [];

  @override
  void initState() {
    super.initState();
    fetchLikedBranches();
  }

  Future<void> fetchLikedBranches() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.228.138:5000/api/favorites/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          likedBranches = data;
        });
      } else {
        print('❌ Lỗi khi lấy danh sách yêu thích: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi khi gọi API: $e');
    }
  }

  Future<void> removeFavorite(String branchId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'http://192.168.228.138:5000/api/favorites/${widget.userId}/$branchId',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          likedBranches.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá khỏi danh sách yêu thích')),
        );
      } else {
        print('❌ Xoá thất bại: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi xoá yêu thích: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
            ),
          ),
        ),
      ),

      body: likedBranches.isEmpty
          ? const Center(child: Text('Chưa có chi nhánh yêu thích nào'))
          : ListView.builder(
              itemCount: likedBranches.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final branch = likedBranches[index];
                final imageName = branch['image'];
                final hasImage =
                    imageName != null && imageName.toString().isNotEmpty;

                final imageAssetPath = hasImage
                    ? 'assets/imgChiNhanh/$imageName'
                    : 'assets/imgChiNhanh/default_image.png';

                Widget imageWidget = Image.asset(
                  imageAssetPath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/imgChiNhanh/default_image.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                );

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailChiNhanhPage(
                          id: branch['_id'],
                          imagePath: imageAssetPath,
                          name: branch['name'] ?? 'Không rõ tên',
                          address: branch['address'] ?? 'Không có địa chỉ',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: imageWidget,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch['name'] ?? 'Không rõ tên',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  branch['address'] ?? 'Không có địa chỉ',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Đặt bàn',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete, 
                            color: Colors.red,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Xoá yêu thích'),
                                content: const Text(
                                  'Bạn có chắc chắn muốn xoá chi nhánh này khỏi danh sách yêu thích?',
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Huỷ'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  TextButton(
                                    child: const Text('Xoá'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      removeFavorite(branch['_id'], index);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // ✅ Thêm BottomNavigationBar
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
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black,
          currentIndex: 3, // "Tài khoản" (hoặc index bạn muốn)
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.location_pin), label: 'Gần bạn'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yêu thích'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(user: null)));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NearYouPage()));
            } else if (index == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchPage()));
            } else if (index == 3) {
              // Đang ở LikePage => không làm gì
            } else if (index == 4) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccountPage()));
            }
          },
        ),
      ),
    );
  }
}
