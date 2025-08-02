import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> _allBookings = [];
  List<dynamic> _filteredBookings = [];

  String _selectedFilter = 'Tất cả';

  final int _itemsPerPage = 5;
  int _currentPage = 1;

  List<dynamic> get _paginatedBookings {
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    return _filteredBookings.sublist(
      start,
      end > _filteredBookings.length ? _filteredBookings.length : end,
    );
  }

  int get totalPages =>
      (_filteredBookings.length / _itemsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _updateXacNhan(String id, bool isConfirmed) async {
    final url = Uri.parse(
      'http://192.168.228.138:5000/api/bookings/$id/${isConfirmed ? "confirm" : "cancel"}',
    );

    try {
      final response = await (isConfirmed ? http.post(url) : http.put(url));

      if (response.statusCode == 200) {
        await _fetchBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isConfirmed ? '✅ Đã xác nhận đơn' : '❌ Đã hủy đơn'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật xác nhận: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      print('❌ _updateXacNhan error: $e');
    }
  }

  Future<void> _fetchBookings() async {
    final url = Uri.parse('http://192.168.228.138:5000/api/bookings');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> bookings = json.decode(response.body);
        setState(() {
          _allBookings = bookings;
          _filterBookings();
        });
      } else {
        print('❌ Lỗi khi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi kết nối: $e');
    }
  }

  Future<void> _updateThanhToan(String id) async {
    final url = Uri.parse('http://192.168.228.138:5000/api/bookings/$id/pay');
    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        await _fetchBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận thanh toán')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thanh toán: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('❌ _updateThanhToan error: $e');
    }
  }

  void _filterBookings() {
    if (_selectedFilter == 'Tất cả') {
      _filteredBookings = _allBookings;
    } else {
      _filteredBookings = _allBookings
          .where((b) => b['trangThaiThanhToan'] == _selectedFilter)
          .toList();
    }
    _currentPage = 1;
    setState(() {});
  }

  Future<void> _callPhone(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng gọi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: null,
        backgroundColor: const Color.fromARGB(255, 236, 24, 24),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  icon: const Icon(Icons.arrow_drop_down),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _selectedFilter = newValue;
                      _filterBookings();
                    }
                  },
                  items: <String>['Tất cả', 'Chưa thanh toán', 'Đã thanh toán']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        child: _filteredBookings.isEmpty
            ? const Center(child: Text('Không có đơn đặt bàn nào'))
            : Column(
                children: [
                  // Tiêu đề mới thay cho AppBar.title
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Đơn đặt bàn",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _paginatedBookings.length,
                      itemBuilder: (context, index) {
                        final b = _paginatedBookings[index];
                        final date = b['date'] != null
                            ? DateFormat(
                                'dd/MM/yyyy',
                              ).format(DateTime.parse(b['date']))
                            : 'Không rõ';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b['name'] ?? 'Ẩn danh'} - ${b['phone'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Chi nhánh: ${b['chiNhanh'] ?? ''}'),
                                Text('Địa chỉ: ${b['diaChi'] ?? ''}'),
                                Text('Số bàn: ${b['soGhe'] ?? ''}'),
                                Text('Thời gian: $date - ${b['time'] ?? ''}'),
                                if ((b['note'] ?? '').toString().isNotEmpty)
                                  Text('Ghi chú: ${b['note']}'),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b['trangThaiThanhToan'] ?? '',
                                          style: TextStyle(
                                            color:
                                                b['trangThaiThanhToan'] ==
                                                    'Đã thanh toán'
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          b['trangThaiXacNhan'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'Xác nhận',
                                          onPressed: () =>
                                              _updateXacNhan(b['_id'], true),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.orange,
                                          ),
                                          tooltip: 'Hủy',
                                          onPressed: () =>
                                              _updateXacNhan(b['_id'], false),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons
                                                .payments, // hoặc Icons.check_circle nếu bạn thích
                                            color: Colors.purple,
                                          ),
                                          tooltip: 'Xác nhận thanh toán',
                                          onPressed: () =>
                                              _updateThanhToan(b['_id']),
                                        ),

                                        IconButton(
                                          icon: const Icon(
                                            Icons.phone,
                                            color: Colors.blue,
                                          ),
                                          tooltip: 'Liên hệ',
                                          onPressed: () =>
                                              _callPhone(b['phone']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        Text('Trang $_currentPage / $totalPages'),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
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
