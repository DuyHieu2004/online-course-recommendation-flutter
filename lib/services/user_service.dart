import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:khoa_hoc_online/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';


class UserService {
  // Hàm lấy Token từ SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Bước 1: Upload file ảnh lên backend (sau đó backend đẩy lên Cloudinary)
  static Future<String> uploadAvatar(File imageFile) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/users/upload');
    
    var request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['url']; // Trả về link Cloudinary từ API C#
    } else {
      throw Exception('Lỗi upload ảnh: ${response.body}');
    }
  }

  // Bước 2: Cập nhật link ảnh vào Profile
  static Future<void> updateProfile({String? ten, String? tieuSu, String? linkAnhDaiDien}) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/users/profile');

    final Map<String, dynamic> body = {};
    if (ten != null) body['ten'] = ten;
    if (tieuSu != null) body['tieuSu'] = tieuSu;
    if (linkAnhDaiDien != null) body['linkAnhDaiDien'] = linkAnhDaiDien;

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi cập nhật profile: ${response.body}');
    }
  }

  // Bước 3: Lấy thông tin Profile (bao gồm ảnh và tiểu sử)
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/users/profile');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.');
    } else {
      final errorMsg = response.body.isNotEmpty ? response.body : 'Lỗi không xác định (Mã lỗi: ${response.statusCode})';
      throw Exception('Lỗi lấy profile: $errorMsg');
    }
  }

  // Bước 4: Lấy cấu hình thông báo
  static Future<List<dynamic>> getNotificationSettings() async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/users/debugroute');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi lấy cài đặt: ${response.body}');
    }
  }

  // Bước 5: Cập nhật cấu hình thông báo
  static Future<void> updateNotificationSettings(List<dynamic> settings) async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/users/debugroute');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(settings),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi cập nhật cài đặt: ${response.body}');
    }
  }

  // Bước 6: Xóa tài khoản (vô hiệu hóa)
  static Future<void> deactivateAccount() async {
    final token = await _getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}/users/profile');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi vô hiệu hóa tài khoản: ${response.body}');
    }
  }
}