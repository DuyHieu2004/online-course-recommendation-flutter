import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import 'course_details_screen.dart';
import 'package:shimmer/shimmer.dart';

class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({super.key});

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  List<RecommendedCourse> personalized = [];
  List<RecommendedCourse> collaborative = [];
  List<RecommendedCourse> trending = [];
  List<dynamic> userInterests = [];
  List<Category> allCategories = [];
  bool isLoading = true;
  bool isEditingInterests = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    final results = await Future.wait([
      CourseService.getRecommendedCourses(),
      CourseService.getCollaborativeCourses(),
      CourseService.getUserInterests(),
      CourseService.getAllCategories(),
      CourseService.getPopularCourses(),
    ]);

    setState(() {
      personalized = results[0] as List<RecommendedCourse>;
      collaborative = results[1] as List<RecommendedCourse>;
      userInterests = results[2] as List<dynamic>;
      allCategories = results[3] as List<Category>;
      trending = results[4] as List<RecommendedCourse>;
      isLoading = false;
    });
  }

  Future<void> _toggleEditInterests() async {
    if (isEditingInterests) {
      // Save
      final ids = userInterests.map((e) => e['maTheLoai'] as int).toList();
      await CourseService.updateUserInterests(ids);
      _loadAllData();
    }
    setState(() => isEditingInterests = !isEditingInterests);
  }

  bool _isInterest(int catId) {
    return userInterests.any((element) => element['maTheLoai'] == catId);
  }

  void _toggleInterest(Category cat) {
    if (!isEditingInterests) return;
    setState(() {
      if (_isInterest(cat.id)) {
        userInterests.removeWhere((element) => element['maTheLoai'] == cat.id);
      } else {
        userInterests.add({'maTheLoai': cat.id, 'tenTheLoai': cat.name});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildInterestsSection(),
                  const SizedBox(height: 32),
                  if (isLoading)
                    _buildShimmerLoading()
                  else if (personalized.isEmpty && collaborative.isEmpty && trending.isEmpty)
                    _buildEmptyState()
                  else ...[
                    if (personalized.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Gợi ý cá nhân hoá",
                        Icons.auto_awesome,
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 16),
                      _buildTopMatchesList(),
                      const SizedBox(height: 32),
                    ],
                    if (trending.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Xu hướng hiện nay",
                        Icons.local_fire_department,
                        const Color(0xFFEA580C),
                      ),
                      const SizedBox(height: 16),
                      _buildCourseCarousel(trending, isTrending: true),
                      const SizedBox(height: 32),
                    ],
                    if (collaborative.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Người học tương tự cũng xem",
                        Icons.people_outline,
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 16),
                      _buildCourseCarousel(collaborative),
                      const SizedBox(height: 40),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF8B5CF6).withOpacity(0.1), const Color(0xFF3B82F6).withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                "AI Recommendation",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
              ),
              const Text(
                "Lộ trình học tập cá nhân của bạn",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Sở thích của bạn",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: _toggleEditInterests,
                child: Text(isEditingInterests ? "Lưu lại" : "Chỉnh sửa"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (isEditingInterests ? allCategories : userInterests).map<Widget>((item) {
              final id = isEditingInterests ? (item as Category).id : (item['maTheLoai'] as int);
              final name = isEditingInterests ? (item as Category).name : (item['tenTheLoai'] as String);
              final active = _isInterest(id);

              return GestureDetector(
                onTap: () => isEditingInterests ? _toggleInterest(item as Category) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFEA580C) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: active ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                      if (active && isEditingInterests) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check, size: 14, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTopMatchesList() {
    return Column(
      children: personalized.map((course) => _buildLargeCourseCard(course)).toList(),
    );
  }

  Widget _buildLargeCourseCard(RecommendedCourse course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailsScreen(courseId: course.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: course.imageUrl != null
                        ? Image.network(course.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)
                        : Container(height: 180, color: const Color(0xFFF1F5F9), child: const Icon(Icons.school, size: 64, color: Colors.grey)),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${(course.rating * 20).toInt()}% Match",
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF8B5CF6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.instructorName ?? "Chưa có giảng viên",
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${course.price.toInt()}đ",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(12)),
                          child: const Text("Chi tiết", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
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

  Widget _buildCourseCarousel(List<RecommendedCourse> list, {bool isTrending = false}) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        itemBuilder: (context, index) => _buildSmallCourseCard(list[index], isTrending: isTrending),
      ),
    );
  }

  Widget _buildSmallCourseCard(RecommendedCourse course, {bool isTrending = false}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: course.imageUrl != null
                    ? Image.network(course.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover)
                    : Container(height: 120, color: const Color(0xFFF1F5F9), child: const Icon(Icons.school, size: 40, color: Colors.grey)),
              ),
              if (isTrending)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    child: const Text("HOT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${course.price.toInt()}đ",
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEA580C)),
                    ),
                    const Icon(Icons.add_circle_outline, color: Color(0xFF64748B), size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 20),
          Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Bạn chưa có lịch sử học tập",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            "Hãy chọn sở thích hoặc bắt đầu học để AI đề xuất chính xác hơn.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
