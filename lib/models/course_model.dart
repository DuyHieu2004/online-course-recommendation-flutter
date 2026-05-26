import 'package:flutter/foundation.dart';

class ApiCourse {
  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String? imageUrl;
  final String? instructorName;

  ApiCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    this.imageUrl,
    this.instructorName,
  });

  factory ApiCourse.fromJson(Map<String, dynamic> json) {
    String? instructor;
    if (json['giangVien'] is List && (json['giangVien'] as List).isNotEmpty) {
      instructor = json['giangVien'][0]['ten'];
    }
    
    return ApiCourse(
      id: json['maKhoaHoc'] ?? 0,
      title: json['tieuDe'] ?? '',
      description: json['moTa'] ?? '',
      price: (json['giaGoc'] ?? 0).toDouble(),
      rating: (json['tbdanhGia'] ?? 0).toDouble(),
      imageUrl: json['anhUrl'],
      instructorName: instructor,
    );
  }
}

class RecommendedCourse {
  final int id;
  final String title;
  final double rating;
  final double price;
  final double score; // Add score
  final String? imageUrl;
  final String? instructorName;

  RecommendedCourse({
    required this.id,
    required this.title,
    required this.rating,
    required this.price,
    this.score = 0.0,
    this.imageUrl,
    this.instructorName,
  });

  factory RecommendedCourse.fromJson(Map<String, dynamic> json) {
    return RecommendedCourse(
      id: json['courseId'] ?? json['CourseId'] ?? 0,
      title: json['title'] ?? json['Title'] ?? '',
      rating: (json['averageRating'] ?? json['AverageRating'] ?? 0).toDouble(),
      price: (json['originalPrice'] ?? json['OriginalPrice'] ?? 0).toDouble(),
      score: (json['score'] ?? json['Score'] ?? 0.0).toDouble(),
      imageUrl: json['image'] ?? json['Image'],
      instructorName: json['instructor'] ?? json['Instructor'],
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;

  Category({required this.id, required this.name, this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['maTheLoai'] ?? json['MaTheLoai'] ?? 0,
      name: json['ten'] ?? json['Ten'] ?? json['tenTheLoai'] ?? 'Chưa có tên',
      description: json['moTa'] ?? json['MoTa'],
    );
  }
}

class EnrolledCourse {
  final int id;
  final String title;
  final double progress;
  final String status;
  final String? imageUrl;
  final String? instructorName;
  final DateTime? enrollmentDate;
  final DateTime? expiryDate;

  final Map<String, dynamic> rawJson;

  EnrolledCourse({
    required this.id,
    required this.title,
    required this.progress,
    required this.status,
    this.imageUrl,
    this.instructorName,
    this.enrollmentDate,
    this.expiryDate,
    required this.rawJson,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  bool get isCompleted => progress >= 1.0;

  factory EnrolledCourse.fromJson(Map<String, dynamic> json) {
    final courseJson = json['khoaHoc'] ?? {};
    return EnrolledCourse(
      id: courseJson['maKhoaHoc'] ?? 0,
      title: courseJson['tieuDe'] ?? '',
      progress: (json['phanTramTienDo'] ?? 0).toDouble() / 100,
      status: json['tinhTrang'] ?? '',
      imageUrl: courseJson['anhUrl'],
      instructorName: courseJson['giangVien'],
      enrollmentDate: json['ngayThamGia'] != null ? DateTime.parse(json['ngayThamGia']) : null,
      expiryDate: _parseDate(json, 'KetThuc') ?? _parseDate(json, 'ExpiryDate'),
      rawJson: json,
    );
  }

  static DateTime? _parseDate(Map<String, dynamic> json, String suffix) {
    debugPrint('Parsing date for suffix $suffix. Keys: ${json.keys.toList()}');
    // Check root level
    for (var key in json.keys) {
      if (key.toLowerCase().endsWith(suffix.toLowerCase())) {
        final val = json[key];
        if (val != null && val.toString().isNotEmpty) {
          try {
            return DateTime.parse(val.toString());
          } catch (e) {
            debugPrint('Error parsing date for key $key: $e');
          }
        }
      }
    }
    // Check nested course level just in case
    final courseJson = json['khoaHoc'] ?? json['KhoaHoc'];
    if (courseJson is Map<String, dynamic>) {
      for (var key in courseJson.keys) {
        if (key.toLowerCase().endsWith(suffix.toLowerCase())) {
          final val = courseJson[key];
          if (val != null && val.toString().isNotEmpty) {
            try {
              return DateTime.parse(val.toString());
            } catch (e) {
              debugPrint('Error parsing date in courseJson for key $key: $e');
            }
          }
        }
      }
    }
    return null;
  }
}
