import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingHistoryPage extends StatefulWidget {
  final String userId;

  const BookingHistoryPage({super.key, required this.userId});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  List<dynamic> _bookings = [];
  List<dynamic> _filteredBookings = [];
  bool _loading = true;
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _selectedStatus = 'Tất cả';

  final List<String> _statusOptions = [
    'Tất cả',
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    fetchBookingHistory();
  }

  Future<void> fetchBookingHistory() async {
    final url = Uri.parse(
      'http://192.168.228.138:5000/api/bookings/history/${widget.userId}',
    );
    try {
      final response = await http.get(url);
      final body = json.decode(response.body);

      setState(() {
        _loading = false;
        if (response.statusCode == 200 && body is List) {
          _bookings = body;
          _applyFilters();
        } else {
          _bookings = [];
          _filteredBookings = [];
        }
        _currentPage = 0;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _bookings = [];
        _filteredBookings = [];
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBookings = _bookings.where((booking) {
        final status = booking['trangThaiXacNhan'] ?? 'Chờ xác nhận';
        final matchesStatus =
            _selectedStatus == 'Tất cả' || status == _selectedStatus;
        return matchesStatus;
      }).toList();
      _filteredBookings.sort((a, b) => b['date'].compareTo(a['date']));
      _currentPage = 0;
    });
  }

  void _showBookingDetailsDialog(Map<String, dynamic> booking) {
    final formattedDate = _formatDate(booking['date']);
    final formattedTime = _formatTime(booking['time']);
    final userName = booking['name'] ?? "Ẩn danh";
    final phone = booking['phone'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chi tiết đơn đặt bàn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Người đặt: $userName"),
            Text("SĐT: $phone"),
            Text("Chi nhánh: ${booking['chiNhanh'] ?? ''}"),
            Text("Địa chỉ: ${booking['diaChi'] ?? ''}"),
            Text("Ngày: $formattedDate"),
            Text("Giờ: $formattedTime"),
            Text("Số bàn: ${booking['soGhe'] ?? ''}"),
            Text("Ghi chú: ${booking['note'] ?? ''}"),
            Text(
              "Trạng thái: ${booking['trangThaiXacNhan'] ?? 'Chờ xác nhận'}",
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Đóng"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhoneDialer(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      phoneNumber = "0375028860";
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể mở ứng dụng gọi điện")),
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final time = DateFormat('HH:mm').parse(timeStr);
      return DateFormat('HH:mm').format(time);
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredBookings.length / _itemsPerPage).ceil();
    final start = _currentPage * _itemsPerPage;
    final end = (_currentPage + 1) * _itemsPerPage;
    final currentItems =
        (_filteredBookings.isEmpty || start >= _filteredBookings.length)
        ? []
        : _filteredBookings.sublist(
            start,
            end > _filteredBookings.length ? _filteredBookings.length : end,
          );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: null, // Giữ nguyên null
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
          ),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              items: _statusOptions
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                    _applyFilters();
                  });
                }
              },
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Center(
                    child: Text(
                      'Lịch sử đặt bàn',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredBookings.isEmpty
                      ? const Center(child: Text("Không có đơn nào phù hợp"))
                      : ListView.builder(
                          itemCount: currentItems.length,
                          itemBuilder: (context, index) {
                            final b = currentItems[index];
                            final status =
                                b['trangThaiXacNhan'] ?? 'Chờ xác nhận';
                            Color statusColor;
                            IconData statusIcon;
                            if (status == 'Đã hủy') {
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                            } else if (status == 'Đã xác nhận') {
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                            } else {
                              statusColor = Colors.orange;
                              statusIcon = Icons.hourglass_top;
                            }
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.event_note,
                                  color: statusColor,
                                ),
                                title: Text(
                                  "${b['chiNhanh'] ?? ''} - ${_formatDate(b['date'])}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Giờ: ${_formatTime(b['time'])} | Bàn: ${b['soGhe'] ?? ''}",
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showBookingDetailsDialog(b),
                              ),
                            );
                          },
                        ),
                ),
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Text("Trang ${_currentPage + 1} / $totalPages"),
                        IconButton(
                          onPressed: _currentPage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
