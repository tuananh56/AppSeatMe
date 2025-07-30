import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'detailchinhanh.dart'; // NHỚ import file trang chi tiết

class NearYouPage extends StatefulWidget {
  const NearYouPage({super.key});

  @override
  State<NearYouPage> createState() => _NearYouPageState();
}

class _NearYouPageState extends State<NearYouPage> {
  List<dynamic> _branches = [];
  bool _loading = false;

  Future<void> _getNearbyBranches() async {
    setState(() => _loading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _showError('Dịch vụ vị trí chưa bật');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _showError('Bạn đã từ chối quyền truy cập vị trí');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return _showError('Bạn cần cấp quyền vị trí trong cài đặt');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url =
          'http://192.168.126.138:5000/api/branches/nearby?lat=${position.latitude}&lng=${position.longitude}&distance=20000';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _branches = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        _showError('Lỗi server khi lấy chi nhánh gần bạn');
      }
    } catch (e) {
      _showError('Lỗi lấy vị trí hoặc dữ liệu: $e');
    }
  }

  void _showError(String message) {
    setState(() => _loading = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Chi nhánh gần bạn',
          style: TextStyle(color: Colors.black),
        ),
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? _buildRequestView()
              : _buildBranchListView(),
    );
  }

  Widget _buildRequestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 50,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vui lòng cho phép ứng dụng truy cập vị trí\nđể tìm địa điểm xung quanh bạn',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _getNearbyBranches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Tìm chi nhánh gần bạn',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _branches.length,
      itemBuilder: (context, index) {
        final branch = _branches[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailChiNhanhPage(
                  imagePath: 'assets/imgChiNhanh/${branch['image']}',
                  name: branch['name'],
                  address: branch['address'],
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/imgChiNhanh/${branch['image']}',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          branch['address'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
