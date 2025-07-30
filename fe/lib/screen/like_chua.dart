import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_dat_ban/screen/detailchinhanh.dart';

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
        Uri.parse('http://192.168.126.138:5000/api/favorites/${widget.userId}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with back button and title
          Container(
            padding: const EdgeInsets.only(top: 40, left: 8, right: 16, bottom: 16),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Yêu thích',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          // Nội dung danh sách yêu thích
          Expanded(
            child: likedBranches.isEmpty
                ? const Center(child: Text('Chưa có chi nhánh yêu thích nào'))
                : ListView.builder(
                    itemCount: likedBranches.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final branch = likedBranches[index];
                      final imageName = branch['image'];
                      final hasImage = imageName != null && imageName.toString().isNotEmpty;

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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
