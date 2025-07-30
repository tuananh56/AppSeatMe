import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'order.dart';
import 'login.dart';

class BranchService {
  static const String baseUrl = 'http://192.168.126.138:5000/api/branches';

  static Future<List<dynamic>> fetchBranches() async {
    try {
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Lỗi khi tải danh sách chi nhánh');
      }
    } catch (e) {
      print('❌ Lỗi khi gọi API: $e');
      return [];
    }
  }
}

class DetailChiNhanhPage extends StatefulWidget {
  final String imagePath;
  final String name;
  final String address;

  const DetailChiNhanhPage({
    super.key,
    required this.imagePath,
    required this.name,
    required this.address,
  });

  @override
  State<DetailChiNhanhPage> createState() => _DetailChiNhanhPageState();
}

class _DetailChiNhanhPageState extends State<DetailChiNhanhPage> {
  List<dynamic> relatedBranches = [];
  bool isLiked = false;
  String? currentBranchId;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
     _checkIsLiked();
    _initData();
  }

  Future<void> _initData() async {
    prefs = await SharedPreferences.getInstance();
    await _loadBranches();

    if (currentBranchId != null) {
      await _checkFavoriteStatus();
    }
  }

  Future<void> _checkIsLiked() async {
  final userJson = prefs.getString('user');
  if (userJson == null || currentBranchId == null) return;

  final userId = jsonDecode(userJson)['_id'];

  try {
    final res = await http.get(
      Uri.parse('http://192.168.126.138:5000/api/favorites/check?userId=$userId&branchId=$currentBranchId'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        isLiked = data['exists']; // true nếu đã thích
      });
    }
  } catch (e) {
    print('❌ Lỗi khi kiểm tra yêu thích: $e');
  }
}

  Future<void> _loadBranches() async {
    final allBranches = await BranchService.fetchBranches();

    final current = allBranches.firstWhere(
      (b) =>
          'assets/imgChiNhanh/${b['image']}' == widget.imagePath &&
          b['name'] == widget.name,
      orElse: () => null,
    );

    if (current != null) {
      currentBranchId = current['_id'];
    }

    final filtered = allBranches
        .where((b) => 'assets/imgChiNhanh/${b['image']}' != widget.imagePath)
        .take(3)
        .toList();

    setState(() {
      relatedBranches = filtered;
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final userJson = prefs.getString('user');
    if (userJson == null || currentBranchId == null) return;

    final userId = jsonDecode(userJson)['_id'];

    final res = await http.get(
      Uri.parse(
        'http://192.168.126.138:5000/api/favorites/check?userId=$userId&branchId=$currentBranchId',
      ),
    );

    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      setState(() {
        isLiked = result['isFavorite'] == true || result['exists'] == true;
      });
    }
  }

  Future<void> _toggleLike() async {
    final userJson = prefs.getString('user');
    if (userJson == null || currentBranchId == null) return;

    final userId = jsonDecode(userJson)['_id'];

    if (isLiked) {
      // Đã like → Gỡ like
      final res = await http.delete(
        Uri.parse('http://192.168.126.138:5000/api/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'branchId': currentBranchId}),
      );

      if (res.statusCode == 200) {
        setState(() {
          isLiked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Đã xoá khỏi yêu thích')),
        );
      } else {
        print('❌ Lỗi xoá yêu thích: ${res.body}');
      }
    } else {
      // Chưa like → Thêm yêu thích
      final res = await http.post(
        Uri.parse('http://192.168.126.138:5000/api/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'branchId': currentBranchId}),
      );

      if (res.statusCode == 201) {
        setState(() {
          isLiked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã thêm vào yêu thích')),
        );
      } else {
        print('❌ Không thể thêm yêu thích: ${res.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                widget.imagePath,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 60,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    onPressed: _toggleLike,
                  ),
                ),
              ),
              const Positioned(
                top: 40,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.share),
                ),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.address,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            final isLoggedIn =
                                prefs.getBool('is_logged_in') ?? false;
                            if (!isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderPage(
                                    imagePath: widget.imagePath,
                                    name: widget.name,
                                    address: widget.address,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Đặt ngay',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Các chi nhánh gần đây',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: relatedBranches.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: relatedBranches.length,
                            itemBuilder: (context, index) {
                              final branch = relatedBranches[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailChiNhanhPage(
                                          imagePath:
                                              'assets/imgChiNhanh/${branch['image']}',
                                          name: branch['name'],
                                          address: branch['address'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          'assets/imgChiNhanh/${branch['image']}',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              branch['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              branch['address'],
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Đặt bàn giữ chỗ',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
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
            ),
          ),
        ],
      ),
    );
  }
}
