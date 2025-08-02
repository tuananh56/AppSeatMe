import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.228.138:5000/api/auth';

  /// Đăng ký tài khoản với ảnh đại diện (multipart/form-data)
  static Future<String?> register(
  String name,
  String email,
  String password,
  String imagePath,
  String phone, 
  String confirmPassword,
) async {
  final uri = Uri.parse('$baseUrl/register');

  try {
    var request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['confirmPassword'] = confirmPassword // ✅ Bổ sung dòng này
      ..fields['phone'] = phone;

    print('📤 Sending fields:');
    print('📤 name: $name');
    print('📤 email: $email');
    print('📤 password: $password');
    print('📤 confirmPassword: $confirmPassword');
    print('📤 phone: $phone');
    print('📤 imagePath: $imagePath');

    if (imagePath.isNotEmpty) {
      final file = File(imagePath);
      final fileName = basename(file.path);
      request.files.add(
        await http.MultipartFile.fromPath('image', file.path, filename: fileName),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('📥 Mã phản hồi: ${response.statusCode}');
    print('📥 Nội dung: ${response.body}');

    if (response.statusCode == 201) {
      return null; // ✅ Thành công
    } else {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Đăng ký thất bại';
    }
  } catch (e) {
    print('❌ Lỗi kết nối khi gửi Multipart: $e');
    return 'Không thể kết nối đến máy chủ';
  }
}



  /// Đăng nhập tài khoản
  static Future<dynamic> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['user']; // Trả về user (Map)
      } else {
        return data['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      print('❌ Lỗi kết nối API login: $e');
      return 'Không thể kết nối đến máy chủ';
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
  final url = Uri.parse('$baseUrl/notifications/$userId');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      print('❌ Không thể tải thông báo');
      return [];
    }
  } catch (e) {
    print('❌ Lỗi tải thông báo: $e');
    return [];
  }
}

  /// ✅ Cập nhật hồ sơ người dùng
  static Future<String?> updateProfile({
    required String name,
    required String phone,
    File? imageFile,
    String? currentPassword,
    String? newPassword,
    required String userId,
  }) async {
    final uri = Uri.parse('http://192.168.228.138:5000/api/auth/$userId');

    try {
      final request = http.MultipartRequest('PUT', uri);

      request.fields['name'] = name;
      request.fields['phone'] = phone;

      if (currentPassword != null && newPassword != null) {
        request.fields['currentPassword'] = currentPassword;
        request.fields['newPassword'] = newPassword;
      }

      if (imageFile != null) {
        final fileName = basename(imageFile.path);
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path, filename: fileName),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Update response: ${response.statusCode}');
      print('📥 Update body: ${response.body}');

      if (response.statusCode == 200) {
        return null; // ✅ Thành công
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Cập nhật thất bại';
      }
    } catch (e) {
      print('❌ Lỗi kết nối khi cập nhật hồ sơ: $e');
      return 'Không thể kết nối đến máy chủ';
    }
  }


}
