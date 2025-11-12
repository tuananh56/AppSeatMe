import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_dat_ban/screen/detailchinhanh.dart';
import 'package:app_dat_ban/screen/home.dart';
import 'package:app_dat_ban/screen/nearyou.dart';
import 'package:app_dat_ban/screen/search.dart';
import 'more.dart';
import 'package:app_dat_ban/screen/account.dart';
import 'package:app_dat_ban/screen/admin.dart' as admin;

class LikePage extends StatefulWidget {
  final String userId;

  const LikePage({super.key, required this.userId});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  List<dynamic> likedBranches = [];
  Map<String, dynamic>? _user;
  String? _userRole;

  final int _itemsPerPage = 5;
  int _currentPage = 1;

  List<dynamic> get _paginatedLikes {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    return likedBranches.sublist(
      startIndex,
      endIndex > likedBranches.length ? likedBranches.length : endIndex,
    );
  }

  int get totalPages => (likedBranches.length / _itemsPerPage).ceil();

  @override
  void initState() {
    super.initState();
    _loadUser();
    fetchLikedBranches();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      final parsedUser = json.decode(userData);
      setState(() {
        _user = parsedUser;
        _userRole = parsedUser['role'];
      });
    }
  }

  Future<void> fetchLikedBranches() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.16.217.138:5000/api/favorites/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          likedBranches = data;
          _currentPage = 1; // Reset trang về đầu mỗi khi load mới
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
          'http://172.16.217.138:5000/api/favorites/${widget.userId}/$branchId',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          likedBranches.removeAt((_currentPage - 1) * _itemsPerPage + index);
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
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _paginatedLikes.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final branch = _paginatedLikes[index];
                        final imageName = branch['image'];
                        final hasImage =
                            imageName != null &&
                            imageName.toString().isNotEmpty;

                        final imageAssetPath = hasImage
                            ? 'assets/imgChiNhanh/$imageName'
                            : 'assets/imgChiNhanh/default_image.png';

                        Widget imageWidget = Image.asset(
                          imageAssetPath,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
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
                                  address:
                                      branch['address'] ?? 'Không có địa chỉ',
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          branch['address'] ??
                                              'Không có địa chỉ',
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
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          TextButton(
                                            child: const Text('Xoá'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              removeFavorite(
                                                branch['_id'],
                                                index,
                                              );
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: SafeArea(
                      child: Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: () {
                          const visiblePages = 3;
                          List<Widget> buttons = [];

                          void addButton(int pageNum) {
                            buttons.add(
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage = pageNum;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  backgroundColor: _currentPage == pageNum
                                      ? Colors.red
                                      : Colors.grey[300],
                                  foregroundColor: _currentPage == pageNum
                                      ? Colors.white
                                      : Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('$pageNum'),
                              ),
                            );
                          }

                          // Trang đầu nếu cần
                          if (_currentPage > visiblePages) {
                            addButton(1);
                            buttons.add(const Text('...'));
                          }

                          // Các trang gần currentPage
                          int start = (_currentPage - 1).clamp(1, totalPages);
                          int end = (_currentPage + 1).clamp(1, totalPages);
                          for (int i = start; i <= end; i++) {
                            addButton(i);
                          }

                          // Trang cuối nếu cần
                          if (_currentPage < totalPages - (visiblePages - 1)) {
                            buttons.add(const Text('...'));
                            addButton(totalPages);
                          }
                          return buttons;
                        }(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
