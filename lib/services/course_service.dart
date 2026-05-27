import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course_model.dart';
import '../api_constants.dart';
import 'auth_service.dart';

class CourseService {
  static Future<List<ApiCourse>> searchCourses(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Courses?search=$query'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coursesJson = data['data'];
        return coursesJson.map((json) => ApiCourse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getCourseDetails(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Courses/$courseId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<RecommendedCourse>> getRecommendedCourses() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/Recommendation/user-profile/${user.userId}',
        ),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => RecommendedCourse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMyCourses() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Learning/my-courses'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getCourseContent(int courseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Learning/course/$courseId'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 3. THÊM HÀM NÀY: Đánh dấu hoàn thành bài học
  static Future<Map<String, dynamic>?> completeLesson(int lessonId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Learning/lesson/$lessonId/complete'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> buyCourse(int courseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;

    try {
      // 1. Add to cart
      final addCartRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Cart/$courseId'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );

      // If status is not 200 and not 400 (already in cart/owned), fail
      if (addCartRes.statusCode != 200 && addCartRes.statusCode != 400) {
        return false;
      }

      // 2. Checkout the cart
      final checkoutRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Orders/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({'PhuongThucThanhToan': 'Thanh toán trực tiếp'}),
      );

      return checkoutRes.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rateCourse(
    int courseId,
    double rating,
    String review,
  ) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Interactions/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({
          'MaKhoaHoc': courseId,
          'Rating': rating,
          'BinhLuan': review,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> toggleBookmark(int courseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Interactions/like/$courseId'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<ApiCourse>> getBookmarks() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Interactions/likes'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => ApiCourse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Lấy danh sách khóa học (có phân trang, tìm kiếm, lọc danh mục, sắp xếp)
  static Future<List<ApiCourse>> getCourses({
    int page = 1,
    int pageSize = 50, // Lấy nhiều một chút để lọc client-side giống web
    String? search,
    int? categoryId,
    String? sortBy,
  }) async {
    try {
      String url =
          '${ApiConstants.baseUrl}/Courses?page=$page&pageSize=$pageSize';
      if (search != null && search.isNotEmpty) url += '&search=$search';
      if (categoryId != null) url += '&categoryId=$categoryId';
      if (sortBy != null && sortBy.isNotEmpty) url += '&sortBy=$sortBy';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coursesJson =
            data['data'] ??
            data; // Tuỳ thuộc vào API trả về mảng hay object có key 'data'
        return coursesJson.map((json) => ApiCourse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching courses: $e");
      return [];
    }
  }

  // Lấy danh sách danh mục để làm bộ lọc
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Categories'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Lấy đánh giá của khóa học
  static Future<List<dynamic>> getCourseReviews(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Courses/$courseId/reviews'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ??
            data; // Tuỳ API trả về mảng trực tiếp hay bọc trong 'data'
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Lấy khóa học liên quan (Item-based)
  static Future<List<dynamic>> getSimilarCourses(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/Recommendation/similar-course/$courseId',
        ),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // API GIỎ HÀNG & THANH TOÁN
  // ==========================================

  static Future<List<dynamic>> getCart() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];
    try {
      // Đổi thành chữ thường /cart đồng bộ với api.service.ts
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/cart'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // BỘ QUÉT THÔNG MINH: Tự động bóc tách mảng danh sách bất kể Backend trả về cấu trúc nào
        if (data is List) {
          return data;
        } else if (data is Map) {
          final list =
              data['data'] ??
              data['cartItems'] ??
              data['items'] ??
              data['gioHangChiTiets'] ??
              data['chiTietGioHangs'] ??
              data['chiTiets'];
          if (list is List) return list;
        }
      }
      return [];
    } catch (e) {
      print("Lỗi kết nối Giỏ hàng: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> addToCart(int courseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null)
      return {'success': false, 'message': 'Vui lòng đăng nhập để thực hiện.'};

    try {
      // Đồng bộ route chữ thường /cart/$courseId
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/cart/$courseId'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Đã thêm khóa học vào giỏ hàng!'};
      } else {
        final body = jsonDecode(response.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Khóa học đã có trong giỏ hàng.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ.'};
    }
  }

  static Future<bool> removeFromCart(int courseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/cart/$courseId'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> applyVoucher(String code) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Orders/apply-voucher'),
        headers: {
          'Authorization': 'Bearer ${user.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'maVoucher': code}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'error': jsonDecode(response.body)['message'] ?? 'Mã không hợp lệ',
        };
      }
    } catch (e) {
      return {'error': 'Lỗi kết nối'};
    }
  }

  static Future<Map<String, dynamic>?> checkoutCart(String voucherCode) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Orders/checkout'),
        headers: {
          'Authorization': 'Bearer ${user.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phuongThucThanhToan': 'Chuyển khoản',
          if (voucherCode.isNotEmpty) 'maVoucher': voucherCode,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'error':
              jsonDecode(response.body)['message'] ?? 'Thanh toán thất bại',
        };
      }
    } catch (e) {
      return {'error': 'Lỗi kết nối'};
    }
  }
}
