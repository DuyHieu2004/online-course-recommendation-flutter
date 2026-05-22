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
  final String? imageUrl;
  final String? instructorName;

  RecommendedCourse({
    required this.id,
    required this.title,
    required this.rating,
    required this.price,
    this.imageUrl,
    this.instructorName,
  });

  factory RecommendedCourse.fromJson(Map<String, dynamic> json) {
    return RecommendedCourse(
      id: json['courseId'] ?? 0,
      title: json['title'] ?? '',
      rating: (json['averageRating'] ?? 0).toDouble(),
      price: (json['originalPrice'] ?? 0).toDouble(),
      imageUrl: json['image'],
      instructorName: json['instructor'],
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

  EnrolledCourse({
    required this.id,
    required this.title,
    required this.progress,
    required this.status,
    this.imageUrl,
    this.instructorName,
  });

  factory EnrolledCourse.fromJson(Map<String, dynamic> json) {
    final courseJson = json['khoaHoc'] ?? {};
    return EnrolledCourse(
      id: courseJson['maKhoaHoc'] ?? 0,
      title: courseJson['tieuDe'] ?? '',
      progress: (json['phanTramTienDo'] ?? 0).toDouble() / 100,
      status: json['tinhTrang'] ?? '',
      imageUrl: courseJson['anhUrl'],
      instructorName: courseJson['giangVien'],
    );
  }
}
