import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/payment.dart';

class OrderPage extends StatefulWidget {
  final String imagePath;
  final String name;
  final String address;

  const OrderPage({
    super.key,
    required this.imagePath,
    required this.name,
    required this.address,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  int soGhe = 1;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final noteController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isLoading = false;

  Future<void> _datBan() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null) {
      _showLoginDialog();
      return;
    }

    final userData = jsonDecode(userJson);
    final userId = userData['_id'];
    final userEmail = userData['email'];

    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    final phoneRegex = RegExp(r'^[0-9]{9,11}$');
    if (!phoneRegex.hasMatch(phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }

    final uri = Uri.parse('http://192.168.228.138:5000/api/bookings');

    final body = {
      'userId': userId,
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'soGhe': soGhe,
      'date': selectedDate!.toIso8601String(),
      'time':
          '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}',
      'note': noteController.text.trim(),
      'chiNhanh': widget.name,
      'diaChi': widget.address,
    };

    try {
      setState(() => isLoading = true);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final booking = jsonDecode(response.body)['booking'];
        final arriveDate = DateTime.parse(booking['date']);
        final bookingId = booking['_id'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Payment(
              imagePath: widget.imagePath,
              name: widget.name,
              address: widget.address,
              fullName: nameController.text.trim(),
              phone: phoneController.text.trim(),
              email: userEmail,
              quantity: soGhe,
              arriveTime: arriveDate,
              bookingId: bookingId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đặt bàn thất bại')));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể kết nối tới server')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _showLoginDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔒 Yêu cầu đăng nhập'),
        content: const Text('Vui lòng đăng nhập để thực hiện đặt bàn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget customInputField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Đặt bàn tại ${widget.name}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                widget.imagePath,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            customInputField(
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Tên khách hàng',

                  suffixIcon: Icon(Icons.person, color: Colors.red),
                ),
              ),
            ),
            customInputField(
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Số điện thoại',

                  suffixIcon: Icon(Icons.phone, color: Colors.red),
                ),
              ),
            ),
            customInputField(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nhóm: chữ "Số bàn" + - số +
                  Row(
                    children: [
                      const Text(
                        'Số bàn:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () => setState(() {
                          if (soGhe > 1) soGhe--;
                        }),
                      ),
                      Text(
                        '$soGhe',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.red,
                        onPressed: () => setState(() => soGhe++),
                      ),
                    ],
                  ),

                  // Icon bàn nằm bên phải
                  const Icon(Icons.table_bar, color: Colors.red),
                ],
              ),
            ),

            customInputField(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Ngày đến',

                    suffixIcon: Icon(Icons.calendar_today, color: Colors.red),
                  ),
                  child: Text(
                    selectedDate == null
                        ? 'Chọn ngày'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  ),
                ),
              ),
            ),
            customInputField(
              child: InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) setState(() => selectedTime = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Giờ đến',

                    suffixIcon: Icon(Icons.access_time, color: Colors.red),
                  ),
                  child: Text(
                    selectedTime == null
                        ? 'Chọn giờ'
                        : '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
            customInputField(
              child: TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Ghi chú',
                  hintText: 'Nhập ghi chú',

                  suffixIcon: Icon(Icons.calendar_today, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _datBan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E0000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Đặt bàn',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
