import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course_model.dart';
import '../api_constants.dart';
import 'auth_service.dart';

class CourseService {
  static Future<List<ApiCourse>> searchCourses(String query) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Courses?search=$query'));
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
      final user = await AuthService.getCurrentUser();
      final headers = user != null ? {'Authorization': 'Bearer ${user.token}'} : <String, String>{};
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Courses/$courseId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);
        
        // Extract course
        dynamic courseData;
        if (rawData is Map<String, dynamic>) {
          if (rawData.containsKey('course') && rawData['course'] is Map) {
            courseData = rawData['course'];
          } else if (rawData.containsKey('Course') && rawData['Course'] is Map) {
            courseData = rawData['Course'];
          } else {
            courseData = rawData;
          }
        } else {
          courseData = rawData;
        }

        bool isCompleted = rawData['isCompleted'] ?? false;
        bool isEnrolled = rawData['isEnrolled'] ?? false;
        dynamic userReview = rawData['userReview'];
        if (user != null) {
          // If already enrolled according to main API, or if we want extra progress info
          try {
            final contentResponse = await http.get(
              Uri.parse('${ApiConstants.baseUrl}/Learning/course/$courseId'),
              headers: {'Authorization': 'Bearer ${user.token}'},
            );
            if (contentResponse.statusCode == 200) {
              final contentData = jsonDecode(contentResponse.body);
              isCompleted = (contentData['phanTramTienDo'] ?? 0) >= 100;
              isEnrolled = true; // Confirmed
            }
          } catch (e) {
            // Fallback to what we got from main API
          }

          if (userReview == null && courseData != null && courseData['danhGia'] != null) {
            final reviews = courseData['danhGia'] as List;
            try {
              userReview = reviews.firstWhere(
                (r) => r['nguoiDanhGia'] != null && r['nguoiDanhGia']['maNguoiDung'] == user.userId,
              );
            } catch (e) {
              // Not found
            }
          }
        }

        return {
          'course': courseData,
          'isCompleted': isCompleted,
          'isEnrolled': isEnrolled,
          'userReview': userReview,
        };
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
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Recommendation/user-profile/${user.userId}'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => RecommendedCourse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<RecommendedCourse>> getCollaborativeCourses() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];

    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Recommendation/collaborative/${user.userId}'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => RecommendedCourse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<RecommendedCourse>> getPopularCourses() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Recommendation/popular'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => RecommendedCourse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<EnrolledCourse>> getMyCourses() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Learning/my-courses'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List? coursesJson = data['data'] ?? data['Data'];
        if (coursesJson == null) return [];
        return coursesJson.map((json) => EnrolledCourse.fromJson(json)).toList();
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
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getCourseAnnouncements(int courseId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Courses/$courseId/announcements'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> completeLesson(int lessonId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Learning/lesson/$lessonId/complete'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveLessonTime(int lessonId, int watchTime) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Learning/lesson/$lessonId/time'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}'
        },
        body: jsonEncode(watchTime),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
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

  static Future<bool> enrollCourse(int courseId) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Learning/enroll/$courseId'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rateCourse(int courseId, double rating, String review) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Interactions/rate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode({'MaKhoaHoc': courseId, 'Rating': rating, 'BinhLuan': review}),
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

  static Future<List<dynamic>> getUserInterests() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Users/interests'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateUserInterests(List<int> categoryIds) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/Users/interests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}'
        },
        body: jsonEncode(categoryIds),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Category>> getAllCategories() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Categories?pageSize=100'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List catsJson = data['data'];
        return catsJson.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
