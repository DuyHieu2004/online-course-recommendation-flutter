import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../api_constants.dart';

class AuthService {
  static Future<void> saveAuthData(String token, int userId, String name, String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('userId', userId);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userRole', role);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userRole');
  }

  static Future<UserProfile?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    final name = prefs.getString('userName');
    final email = prefs.getString('userEmail');
    final role = prefs.getString('userRole');

    if (token != null && userId != null) {
      return UserProfile(userId: userId, name: name ?? '', email: email ?? '', role: role ?? 'HocVien', token: token);
    }
    return null;
  }

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Email': email, 'MatKhau': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveAuthData(data['token'], data['userId'], data['userName'], email, data['role']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> register(String name, String email, String password) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/Auth/register'));
      request.fields['Ten'] = name;
      request.fields['Email'] = email;
      request.fields['MatKhau'] = password;
      request.fields['VaiTro'] = 'HocVien';
      
      final response = await request.send();
      print("===================================");
      print(response.statusCode);
      
      print("===================================");
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({'MatKhauCu': oldPassword, 'MatKhauMoi': newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
