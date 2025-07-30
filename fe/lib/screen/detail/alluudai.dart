import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AllUuDaiPage extends StatefulWidget {
  const AllUuDaiPage({super.key});

  @override
  State<AllUuDaiPage> createState() => _AllUuDaiPageState();
}

class _AllUuDaiPageState extends State<AllUuDaiPage> {
  List<Map<String, dynamic>> _deals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDeals();
  }

  Future<void> fetchDeals() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.126.138:5000/api/deals'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _deals = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Lỗi tải ưu đãi');
      }
    } catch (e) {
      print('❌ Lỗi API (deals): $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatDate(String? isoDate) {
    if (isoDate == null) return 'Không rõ';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deals.isEmpty) {
      return const Center(child: Text('Không có ưu đãi nào.'));
    }

    return ListView.builder(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  itemCount: _deals.length,
  itemBuilder: (context, index) {
    final deal = _deals[index];
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/imgUuDai/${deal['image']}',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported),
        ),
      ),
      title: Text(
        deal['title'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('Áp dụng đến: ${formatDate(deal['expiry'])}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  },
);

  }
}
