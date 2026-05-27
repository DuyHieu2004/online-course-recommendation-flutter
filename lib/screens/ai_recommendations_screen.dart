import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import 'course_details_screen.dart';

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  bool _isLoggedIn = false;
  bool _isLoadingTrending = true;
  bool _isLoadingProfile = true;
  bool _isLoadingRelated = true;

  List<dynamic> _trendingCourses = [];
  List<dynamic> _profileCourses = [];
  List<dynamic> _relatedCourses = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      setState(() => _isLoggedIn = true);
      // Gọi song song 3 luồng API giống Angular
      _loadTrending(user.userId);
      _loadProfileBased(user.userId);
      _loadRelatedFromAllEnrolled();
    } else {
      setState(() {
        _isLoggedIn = false;
        _isLoadingTrending = false;
        _isLoadingProfile = false;
        _isLoadingRelated = false;
      });
    }
  }

  // 1. Trending (Có Fallback sang Popular)
  Future<void> _loadTrending(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Recommendation/user-based/$userId'),
      );
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          setState(() {
            _trendingCourses = data.take(4).toList();
            _isLoadingTrending = false;
          });
          return;
        }
      }
      // Fallback
      final fallbackRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Recommendation/popular'),
      );
      if (fallbackRes.statusCode == 200) {
        setState(() {
          _trendingCourses = (jsonDecode(fallbackRes.body) as List)
              .take(4)
              .toList();
        });
      }
    } catch (e) {
      print("Lỗi load trending: $e");
    } finally {
      if (mounted) setState(() => _isLoadingTrending = false);
    }
  }

  // 2. Profile Based
  Future<void> _loadProfileBased(int userId) async {
    try {
      final res = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/Recommendation/user-profile/$userId',
        ),
      );
      if (res.statusCode == 200) {
        setState(() {
          _profileCourses = (jsonDecode(res.body) as List).take(8).toList();
        });
      }
    } catch (e) {
      print("Lỗi load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // 3. Related from Enrolled
  // 3. Related from Enrolled
  Future<void> _loadRelatedFromAllEnrolled() async {
    try {
      final enrolled = await CourseService.getMyCourses();
      if (enrolled.isEmpty) {
        setState(() => _isLoadingRelated = false);
        return;
      }

      // Lấy danh sách ID các khóa học đang học (tối đa 6 khóa để tránh query quá nhiều)
      Set<int> sourceCourseIds = {};
      for (var item in enrolled) {
        dynamic c = item; // Ép về dynamic để tránh lỗi Compile-time
        int id = 0;

        // Bắt mọi trường hợp tên biến ID khóa học có thể có trong Model của bạn
        try {
          id = c.courseId ?? 0;
        } catch (_) {}
        if (id == 0)
          try {
            id = c.maKhoaHoc ?? 0;
          } catch (_) {}
        if (id == 0)
          try {
            id = c.id ?? 0;
          } catch (_) {}

        if (id != 0) {
          sourceCourseIds.add(id);
        }
      }

      if (sourceCourseIds.isEmpty) {
        setState(() => _isLoadingRelated = false);
        return;
      }

      final listIdsToFetch = sourceCourseIds.toList().take(6);

      List<dynamic> allSimilar = [];
      for (int id in listIdsToFetch) {
        final similar = await CourseService.getSimilarCourses(id);
        allSimilar.addAll(similar);
      }

      // Lọc trùng và bỏ những khóa đã mua
      Map<int, dynamic> bestById = {};
      for (var course in allSimilar) {
        int cId =
            course['courseId'] ??
            course['CourseId'] ??
            course['id'] ??
            course['maKhoaHoc'] ??
            0;
        if (cId == 0 || sourceCourseIds.contains(cId)) continue;

        if (!bestById.containsKey(cId) ||
            (course['score'] ?? 0) > (bestById[cId]['score'] ?? 0)) {
          bestById[cId] = course;
        }
      }

      var sortedRelated = bestById.values.toList()
        ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

      setState(() {
        _relatedCourses = sortedRelated.take(8).toList();
      });
    } catch (e) {
      print("Lỗi load related: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gợi ý từ AI',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_fix_high, color: Color(0xFF8E24AA)),
          ),
        ],
      ),
      body: !_isLoggedIn
          ? _buildRequireLogin()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  _buildSection(
                    title: 'Những khóa học thịnh hành nhất',
                    subtitle:
                        'Gợi ý dựa trên những học viên có sở thích tương đồng với bạn.',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    iconBg: Colors.orange.shade50,
                    isLoading: _isLoadingTrending,
                    courses: _trendingCourses,
                    emptyMsg: 'Chưa có đủ dữ liệu học viên tương đồng.',
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    title: 'Người học tương tự bạn cũng xem',
                    subtitle:
                        'Đề xuất cá nhân hóa chuyên sâu dựa trên đánh giá của bạn.',
                    icon: Icons.badge,
                    iconColor: Colors.blue,
                    iconBg: Colors.blue.shade50,
                    isLoading: _isLoadingProfile,
                    courses: _profileCourses,
                    emptyMsg:
                        'Hãy đánh giá thêm các khóa học để AI hiểu rõ hơn sở thích.',
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    title: 'Gợi ý từ lộ trình học của bạn',
                    subtitle:
                        'Mở rộng từ tất cả các khóa học bạn đang theo học.',
                    icon: Icons.layers,
                    iconColor: Colors.purple,
                    iconBg: Colors.purple.shade50,
                    isLoading: _isLoadingRelated,
                    courses: _relatedCourses,
                    emptyMsg:
                        'Ghi danh khóa học để AI phân tích lộ trình tiếp theo.',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildRequireLogin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đăng nhập để xem gợi ý',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hệ thống AI cần phân tích hành vi của bạn để đưa ra các khóa học phù hợp nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isLoading,
    required List<dynamic> courses,
    required String emptyMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (courses.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: Text(
              emptyMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          )
        else
          SizedBox(
            height: 250, // Chiều cao thẻ card
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal, // Scroll ngang cho mobile
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return _buildAiCourseCard(courses[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAiCourseCard(dynamic c) {
    // Trích xuất dữ liệu an toàn từ Map trả về từ Neo4j
    String imageUrl =
        c['image'] ?? c['imageUrl'] ?? c['anhUrl'] ?? c['Image'] ?? '';
    String title = c['title'] ?? c['tieuDe'] ?? c['Title'] ?? 'Khóa học';
    String instructor = c['instructor'] ?? c['giangVien'] ?? 'Giảng viên';
    dynamic price =
        c['price'] ?? c['giaGoc'] ?? c['originalPrice'] ?? c['Price'] ?? 0;
    int id = c['id'] ?? c['maKhoaHoc'] ?? c['courseId'] ?? c['CourseId'] ?? 0;

    // Xử lý ID bị parse thành String
    if (id == 0 && c['courseId'] != null)
      id = int.tryParse(c['courseId'].toString()) ?? 0;

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (id != 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailsScreen(courseId: id),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh khoá học
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: Colors.blueGrey.shade50,
                  image: imageUrl.isNotEmpty && imageUrl.length > 5
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl.isEmpty || imageUrl.length <= 5
                    ? const Center(
                        child: Icon(
                          Icons.school,
                          size: 40,
                          color: Colors.blueGrey,
                        ),
                      )
                    : null,
              ),
              // Thông tin
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      instructor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price == 0 ? 'Miễn phí' : '${price}đ',
                      style: const TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
