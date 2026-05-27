import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import '../models/course_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import 'search_course_screen.dart';
import 'course_details_screen.dart';
import 'course_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _user;
  List<RecommendedCourse> _recommendedCourses = [];
  List<dynamic> _categories = [];
  List<ApiCourse> _popularCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService.getCurrentUser();
    
    // Tải song song các dữ liệu cần thiết
    final categories = await CourseService.getCategories();
    final popular = await CourseService.getCourses(pageSize: 8);

    if (user != null) {
      final recommendations = await CourseService.getRecommendedCourses();

      if (mounted) {
        setState(() {
          _user = user;
          _recommendedCourses = recommendations;
          _categories = categories;
          _popularCourses = popular;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _categories = categories;
          _popularCourses = popular;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            if (_categories.isNotEmpty) ...[
              _buildCategoriesSection(),
              const SizedBox(height: 24),
            ],
            if (_recommendedCourses.isNotEmpty) ...[
              _buildSuggestedCoursesSection(),
              const SizedBox(height: 24),
            ],
            if (_popularCourses.isNotEmpty) ...[
              _buildPopularCoursesSection(),
              const SizedBox(height: 24),
            ],
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

  Widget _buildSuggestedCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Suggested Courses',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 16),
        if (_recommendedCourses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No suggested courses available right now.', style: TextStyle(color: Colors.black54)),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _recommendedCourses.length,
              itemBuilder: (context, index) {
                final course = _recommendedCourses[index];
                return Padding(
                  padding: EdgeInsets.only(right: index == _recommendedCourses.length - 1 ? 0 : 12.0),
                  child: _buildCourseCard(course),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_stories, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildCourseCard(RecommendedCourse course) {
    return InkWell(
      onTap: () {
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
                  child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                      ? Image.network(
                          course.imageUrl!, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                        )
                      : _buildFallbackImage(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '⭐ ${course.rating.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          course.price == 0 ? "Free" : "${course.price}đ",
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
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

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Explore Categories',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final catName = cat['ten'] ?? cat['Ten'] ?? cat['TenTheLoai'] ?? 'Category';
              final catId = cat['maTheLoai'] ?? cat['MaTheLoai'];
              
              return InkWell(
                onTap: () {
                  if (catId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseListScreen(initialCategoryId: catId),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Text(
                    catName,
                    style: const TextStyle(
                      color: Color(0xFF1E88E5), 
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Trending Courses',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _popularCourses.length,
            itemBuilder: (context, index) {
              final course = _popularCourses[index];
              return Padding(
                padding: EdgeInsets.only(right: index == _popularCourses.length - 1 ? 0 : 12.0),
                child: _buildApiCourseCard(course),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApiCourseCard(ApiCourse course) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CourseDetailsScreen(courseId: course.id)),
        );
      },
      child: Container(
        width: 280,
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
                  child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                      ? Image.network(
                          course.imageUrl!, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                        )
                      : _buildFallbackImage(),
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
                    const SizedBox(height: 4),
                    Text(
                      course.instructorName ?? 'E-Learning',
                      style: const TextStyle(color: Colors.black54, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '⭐ ${course.rating.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          course.price == 0 ? "Free" : "${course.price}đ",
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
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
}
