import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import 'models.dart';
import 'sample_data.dart';
import 'course_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Biến chứa dữ liệu API 1: User-based (Collaborative Filtering)
  late Future<List<dynamic>> _recommendationsFuture;

  // Biến chứa dữ liệu API 2: Content-based (Profile/History)
  late Future<List<dynamic>> _profileBasedFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = fetchRecommendations();
    _profileBasedFuture = fetchProfileBasedRecommendations();
  }

  // GỌI API 1: USER-BASED
  Future<List<dynamic>> fetchRecommendations() async {
    try {
      const String baseUrl = 'http://127.0.0.1:5128';
      final url = Uri.parse('$baseUrl/api/Recommendation/user-based/542');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Chi tiết lỗi: $e');
    }
  }

  // GỌI API 2: CONTENT-BASED (User Profile)
  Future<List<dynamic>> fetchProfileBasedRecommendations() async {
    try {
      const String baseUrl = 'http://127.0.0.1:5128';
      // Gọi API mới theo hồ sơ user
      final url = Uri.parse(
        '$baseUrl/api/Recommendation/content-based/user-profile/542',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Chi tiết lỗi: $e');
    }
  }

  void _retryUserBasedFetch() {
    setState(() {
      _recommendationsFuture = fetchRecommendations();
    });
  }

  void _retryProfileBasedFetch() {
    setState(() {
      _profileBasedFuture = fetchProfileBasedRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 16),

            // Thay thế Mentors tĩnh bằng API Content-Based
            _buildProfileBasedSection(),

            const SizedBox(height: 24),

            // API User-Based (Collab)
            _buildSessionsSection(),

            const SizedBox(height: 24),
            _buildGridSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFFCC33),
      elevation: 0,
      leading: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 2.5,
                color: Colors.black,
                margin: const EdgeInsets.only(bottom: 6),
              ),
              Container(
                width: 14,
                height: 2.5,
                color: Colors.black,
                margin: const EdgeInsets.only(bottom: 6),
              ),
              Container(width: 22, height: 2.5, color: Colors.black),
            ],
          ),
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.black, fontSize: 18),
              children: [
                TextSpan(text: 'Welcome, '),
                TextSpan(
                  text: 'Joffin',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse Sunbird library to find relevant content\nbased on your preferences (Board, Medium, Class)',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'CBSE, English, Class 12',
                style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // UI MỚI: API Content-Based / User Profile
  Widget _buildProfileBasedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recommended Courses\n(Based on your profile)', // Tên mới thay cho Mentor
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: FutureBuilder<List<dynamic>>(
            future: _profileBasedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _retryProfileBasedFetch,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Chưa có gợi ý nào từ hồ sơ của bạn.'),
                );
              }

              final recommendedCourses = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: recommendedCourses.length,
                itemBuilder: (context, index) {
                  final course = recommendedCourses[index];

                  final String apiTitle =
                      course['title'] ??
                      course['Title'] ??
                      course['courseTitle'] ??
                      course['CourseTitle'] ??
                      'Khóa học không tên';
                  final String apiId =
                      course['courseId']?.toString() ??
                      course['CourseId']?.toString() ??
                      'id_$index';
                  final String apiScore =
                      course['score']?.toString() ??
                      course['Score']?.toString() ??
                      '';

                  final sessionApi = Session(
                    id: apiId,
                    title: apiTitle,
                    subtitle: apiScore.isNotEmpty
                        ? 'Profile Score: $apiScore'
                        : 'Khóa học gợi ý',
                  );

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == recommendedCourses.length - 1 ? 0 : 12.0,
                    ),
                    child: _buildSessionCard(context, sessionApi),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // UI CŨ: API User-Based (Collab)
  Widget _buildSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recommended Sessions\n(Based on users similar to you)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: FutureBuilder<List<dynamic>>(
            future: _recommendationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _retryUserBasedFetch,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Chưa có gợi ý nào cho bạn.'));
              }

              final recommendedCourses = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: recommendedCourses.length,
                itemBuilder: (context, index) {
                  final course = recommendedCourses[index];

                  final String apiTitle =
                      course['title'] ??
                      course['Title'] ??
                      course['courseTitle'] ??
                      course['CourseTitle'] ??
                      'Khóa học không tên';
                  final String apiId =
                      course['courseId']?.toString() ??
                      course['CourseId']?.toString() ??
                      'id_$index';
                  final String apiScore =
                      course['score']?.toString() ??
                      course['Score']?.toString() ??
                      '';

                  final sessionApi = Session(
                    id: apiId,
                    title: apiTitle,
                    subtitle: apiScore.isNotEmpty
                        ? 'Similarity Score: $apiScore'
                        : 'Khóa học gợi ý',
                  );

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == recommendedCourses.length - 1 ? 0 : 12.0,
                    ),
                    child: _buildSessionCard(context, sessionApi),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget dùng chung để vẽ thẻ khóa học cho cả 2 List
  Widget _buildSessionCard(BuildContext context, Session session) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              courseId: session.id,
              courseTitle: session.title,
            ),
          ),
        );
      },
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      session.subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learn, Manage and Act',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGridItem(Icons.insert_chart_outlined, 'Programs'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGridItem(
                  Icons.design_services_outlined,
                  'Projects',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String title) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 40, color: const Color(0xFF1E88E5)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
