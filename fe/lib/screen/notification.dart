import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> _allBookings = [];
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchAllBookings();
  }

  Future<void> _fetchAllBookings() async {
    try {
      final res = await http.get(Uri.parse('http://172.16.217.138:5000/api/bookings'));
      if (res.statusCode == 200) {
        setState(() {
          _allBookings = jsonDecode(res.body);
        });
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      print('Lỗi khi tải đơn đặt: $e');
    }
  }

  List<dynamic> get _paidBookings =>
      _allBookings.where((b) => b['trangThaiThanhToan'] == 'Đã thanh toán').toList();

  List<dynamic> get _paginatedPaidBookings {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (_currentPage * _itemsPerPage).clamp(0, _paidBookings.length);
    return _paidBookings.sublist(start, end);
  }

  int get _totalPages =>
      (_paidBookings.length / _itemsPerPage).ceil().clamp(1, 9999);

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng đã thanh toán'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _paidBookings.isEmpty
          ? const Center(child: Text('Không có đơn nào đã thanh toán'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _paginatedPaidBookings.length,
                    itemBuilder: (context, index) {
                      final b = _paginatedPaidBookings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: ListTile(
                          title: Text(b['tenNguoiDat'] ?? 'Ẩn danh'),
                          subtitle: Text('Ngày: ${b['ngayDat']}\nGiờ: ${b['gioDat']}'),
                          trailing: Text(
                            b['trangThaiThanhToan'],
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: _prevPage,
                      child: const Text('Trang trước'),
                    ),
                    Text('Trang $_currentPage / $_totalPages'),
                    ElevatedButton(
                      onPressed: _nextPage,
                      child: const Text('Trang sau'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
