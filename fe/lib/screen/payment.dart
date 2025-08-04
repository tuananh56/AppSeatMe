// ... các import khác giữ nguyên
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Payment extends StatefulWidget {
  final String imagePath;
  final String name;
  final String address;
  final String fullName;
  final String phone;
  final String email;
  final int quantity;
  final DateTime arriveTime;
  final String bookingId;

  const Payment({
    super.key,
    required this.imagePath,
    required this.name,
    required this.address,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.quantity,
    required this.arriveTime,
    required this.bookingId,
  });

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _arrowAnimation;
  String? _selectedMethod;
  late final DateTime endTime;
  late final int tienCoc;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(_controller);
    endTime = widget.arriveTime.add(const Duration(hours: 2));
    tienCoc = widget.quantity * 50000;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedMethod = method;
      _isExpanded = false;
      _controller.reverse();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã chọn: $method')));
  }

  Future<void> _handleDatBan() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phương thức thanh toán')),
      );
      return;
    }

    // 🆕 Sử dụng QR từ api.qrserver.com
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?data=VNPay-${widget.bookingId}-$tienCoc&size=200x200';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quét mã QR để thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              qrUrl,
              width: 200,
              height: 200,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error);
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Phương thức: $_selectedMethod\nTiền cọc: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tienCoc)}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(
                'http://192.168.228.138:5000/api/bookings/${widget.bookingId}/pay',
              );
              try {
                final response = await http.post(url);

                if (response.statusCode == 200) {
                  Navigator.pop(context); // Đóng dialog QR
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Xác nhận thanh toán thành công',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lỗi khi xác nhận thanh toán',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Lỗi kết nối: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Xác nhận đã thanh toán'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String text, String assetPath) {
    return ListTile(
      leading: Image.asset(assetPath, width: 24, height: 24),
      title: Text(text),
      onTap: () => _selectPaymentMethod(text),
    );
  }

  Widget _getPaymentMethodWidget() {
    final Map<String, String> paymentIcons = {
      'Thanh toán bằng Momo': 'assets/imgPayment/momo.png',
      'Thanh toán bằng ngân hàng': 'assets/imgPayment/ATM.png',
      'Thanh toán bằng thẻ tín dụng': 'assets/imgPayment/creditcard.png',
      'Thanh toán bằng ZaloPay': 'assets/imgPayment/zalopay.png',
    };

    String text = _selectedMethod ?? 'Chọn phương thức thanh toán';
    Widget icon = paymentIcons.containsKey(text)
        ? Image.asset(paymentIcons[text]!, width: 24, height: 24)
        : const Icon(Icons.payment);

    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        title: const Text(
          "Thông tin đặt bàn",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    widget.imagePath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.address),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text(
                      'Thời gian đến',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      DateFormat('HH:mm dd/MM/yyyy').format(widget.arriveTime),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Thời gian kết thúc',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(DateFormat('HH:mm dd/MM/yyyy').format(endTime)),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Người đặt bàn",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(widget.fullName),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text("Số điện thoại:"), Text(widget.phone)],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text("Email:"), Text(widget.email)],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Số bàn:"),
                Text(widget.quantity.toString()),
              ],
            ),
            const Divider(height: 30),
            const Text(
              "Chi tiết thanh toán",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tiền cọc (50.000đ/bàn)"),
                Text(currencyFormat.format(tienCoc)),
              ],
            ),
            const Divider(height: 30),
            InkWell(
              onTap: _toggleExpand,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _getPaymentMethodWidget(),
                    RotationTransition(
                      turns: _arrowAnimation,
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              _buildOption(
                'Thanh toán bằng Momo',
                'assets/imgPayment/momo.png',
              ),
              _buildOption(
                'Thanh toán bằng ngân hàng',
                'assets/imgPayment/ATM.png',
              ),
              _buildOption(
                'Thanh toán bằng thẻ tín dụng',
                'assets/imgPayment/creditcard.png',
              ),
              _buildOption(
                'Thanh toán bằng ZaloPay',
                'assets/imgPayment/zalopay.png',
              ),
            ],
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Tổng thanh toán"),
                    Text(
                      currencyFormat.format(tienCoc),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _handleDatBan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đặt bàn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
