import 'package:flutter/material.dart';

class QRPage extends StatelessWidget {
  const QRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên hệ với nhà hàng')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quét mã QR để liên hệ Zalo với nhà hàng:',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.asset('assets/images/qr_zalo.jpg', // 🔁 Thay bằng URL mã QR thật
              width: 250,
              height: 250,
              errorBuilder: (context, error, stackTrace) => const Text('Không tải được mã QR'),
            ),
          ],
        ),
      ),
    );
  }
}
