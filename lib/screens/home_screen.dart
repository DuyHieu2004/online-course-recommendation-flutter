import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import '../models/course_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import 'search_course_screen.dart';
import 'course_details_screen.dart';
// Nhớ import 2 file service của bạn vào nhé
import '../utils/Toast.dart';
import '../utils/QuickAlertService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _user;
  List<RecommendedCourse> _personalizedCourses = [];
  List<RecommendedCourse> _trendingCourses = [];
  bool _isLoading = true;
  String _trendingTitle = 'Trending Courses';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService.getCurrentUser();
      List<RecommendedCourse> personalized = [];
      List<RecommendedCourse> trending = [];
      
      if (user != null) {
        personalized = await CourseService.getRecommendedCourses();
        trending = await CourseService.getCollaborativeCourses();
      }
      
      String title = 'Trending Courses';
      if (trending.isEmpty) {
        trending = await CourseService.getPopularCourses();
        title = 'Trending Courses';
      }
      
      if (mounted) {
        setState(() {
          _user = user;
          _personalizedCourses = personalized;
          _trendingCourses = trending;
          _trendingTitle = title;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Ứng dụng Toast hoặc QuickAlert ngay đây khi có lỗi tải data
      if (mounted) {
        setState(() => _isLoading = false);
        // Có thể dùng ToastUtils.showError('Lỗi kết nối mạng!'); 
        // Hoặc QuickAlert như bên dưới:
        QuickAlertService.showAlertFailure(context, 'Không thể tải dữ liệu. Vui lòng thử lại sau!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Đã sửa lại cái loading cho đẹp và tone-sur-tone với app
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCC33)), // Màu vàng chuẩn
                strokeWidth: 4,
              ),
              SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      );
    
     
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildPersonalizedCoursesSection(),
            if (_personalizedCourses.isNotEmpty) const SizedBox(height: 24),
            _buildTrendingCoursesSection(),
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
              Container(width: 22, height: 2.5, color: Colors.black, margin: const EdgeInsets.only(bottom: 6)),
              Container(width: 14, height: 2.5, color: Colors.black, margin: const EdgeInsets.only(bottom: 6)),
              Container(width: 22, height: 2.5, color: Colors.black),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchCourseScreen()),
            );
          },
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 18),
              children: [
                const TextSpan(text: 'Welcome, '),
                TextSpan(text: _user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse our library to find relevant content\nbased on your preferences',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedCoursesSection() {
    if (_personalizedCourses.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recommended for You',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _personalizedCourses.length,
            itemBuilder: (context, index) {
              final course = _personalizedCourses[index];
              return Padding(
                padding: EdgeInsets.only(right: index == _personalizedCourses.length - 1 ? 0 : 12.0),
                child: _buildCourseCard(course),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _trendingTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),
        if (_trendingCourses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No trending courses available right now.', style: TextStyle(color: Colors.black54)),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _trendingCourses.length,
              itemBuilder: (context, index) {
                final course = _trendingCourses[index];
                return Padding(
                  padding: EdgeInsets.only(right: index == _trendingCourses.length - 1 ? 0 : 12.0),
                  child: _buildCourseCard(course),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(RecommendedCourse course) {
    return InkWell(
      onTap: () {
        // Ví dụ dùng Alert Loading khi click vào xem chi tiết nếu data nặng
        // QuickAlertService.showAlertLoading(context, 'Đang mở khóa học...');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CourseDetailsScreen(courseId: course.id)),
        );
      },
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
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
                  child: course.imageUrl != null 
                      ? Image.network(course.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.school, color: Colors.grey, size: 30),
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
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '⭐ ${course.rating.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
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
          const Text('Learn, Manage and Act', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildGridItem(Icons.insert_chart_outlined, 'Programs')),
              const SizedBox(width: 16),
              Expanded(child: _buildGridItem(Icons.design_services_outlined, 'Projects')),
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
          Container(padding: const EdgeInsets.all(12), child: Icon(icon, size: 40, color: const Color(0xFF1E88E5))),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}