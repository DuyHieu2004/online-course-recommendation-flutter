import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import '../utils/toast_utils.dart';
import 'package:intl/intl.dart';
import 'learning_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final int courseId;
  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _courseData;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  void _loadDetails() async {
    final data = await CourseService.getCourseDetails(widget.courseId);
    if (mounted) {
      setState(() {
        _courseData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_courseData == null) return const Scaffold(body: Center(child: Text('Lỗi tải dữ liệu.')));

    final course = _courseData!['course'];
    final isCompleted = _courseData!['isCompleted'] ?? false;
    final isEnrolled = _courseData!['isEnrolled'] ?? false;
    final isExpired = _courseData!['isExpired'] ?? false;
    final userReview = _courseData!['userReview'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(course),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Nội dung'),
                Tab(text: 'Đánh giá'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverview(course),
                  _buildCurriculum(course),
                  _buildReviews(course, userReview, isCompleted, isEnrolled),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(isEnrolled, isExpired, isCompleted, course['giaGoc']),
    );
  }

  Widget _buildSliverAppBar(dynamic course) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.blue,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (course['anhUrl'] != null)
              Image.network(course['anhUrl'], fit: BoxFit.cover)
            else
              Container(color: Colors.blue.shade800),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course['tieuDe']?.toString() ?? 'Không có tiêu đề', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${course['tbdanhGia'] ?? 0.0} (${course['soLuongDanhGia'] ?? 0} đánh giá)', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(dynamic course) {
    final expiryDate = _courseData!['expiryDate'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expiryDate != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade100)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hạn truy cập: Đến ngày ${DateFormat('dd/MM/yyyy').format(DateTime.parse(expiryDate))}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời hạn học:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      Text('${course['thoiGianHocDuKien'] ?? 0} tháng', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời gian gia hạn:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                      Text('${course['thoiGianChoPhepTre'] ?? 0} ngày', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text('Mô tả khóa học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(course['moTa'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildCurriculum(dynamic course) {
    final List chapters = course['chuongs'] ?? [];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text('Chương ${index + 1}: ${chapter['tieuDe']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${chapter['soBaiHoc']} bài học'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviews(dynamic course, dynamic userReview, bool isCompleted, bool isEnrolled) {
    final List reviews = course['danhGia'] ?? [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (isEnrolled && !isCompleted && userReview == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.grey),
                SizedBox(width: 12),
                Expanded(child: Text('Hoàn thành 100% khóa học để gửi đánh giá của bạn.', style: TextStyle(color: Colors.grey))),
              ],
            ),
          ),
        if (!isEnrolled)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(child: Text('Vui lòng tham gia khóa học để có thể gửi đánh giá.', style: TextStyle(color: Colors.blue))),
              ],
            ),
          ),
        if (userReview != null) ...[
          const Text('Đánh giá của bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildReviewCard(userReview, isMine: true),
          const Divider(height: 40),
        ],
        const Text('Tất cả đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...reviews.map((r) => _buildReviewCard(r)),
      ],
    );
  }

  Widget _buildReviewCard(dynamic r, {bool isMine = false}) {
    final user = r['nguoiDanhGia'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMine ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMine ? Colors.blue.shade200 : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: user['linkAnhDaiDien'] != null ? NetworkImage(user['linkAnhDaiDien']) : null,
                child: user['linkAnhDaiDien'] == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isMine ? 'Bạn (Của bạn)' : (user['ten'] ?? 'Người dùng'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(r['ngayDanhGia'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(r['ngayDanhGia'])) : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Row(children: List.generate(5, (index) => Icon(Icons.star, color: index < (r['rating'] ?? 0) ? Colors.amber : Colors.grey.shade300, size: 16))),
            ],
          ),
          const SizedBox(height: 12),
          Text(r['binhLuan'] ?? '', style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isEnrolled, bool isExpired, bool completed, dynamic price) {
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _buyCourse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rotate_left, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Mua lại để tiếp tục học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isEnrolled) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (completed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.green),
                    SizedBox(width: 12),
                    Text(
                      'Đã hoàn thành 100%',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LearningScreen(courseId: widget.courseId))).then((_) => _loadDetails());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Vào học ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Giá khóa học', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  price != null && price > 0 ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(price) : 'Miễn phí',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _buyCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mua khóa học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _buyCourse() async {
    setState(() => _isLoading = true);
    final success = await CourseService.buyCourse(widget.courseId);
    if (success) {
      if (mounted) {
        ToastUtils.showSuccess('Mua khóa học thành công!');
        _loadDetails();
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Mua khóa học thất bại. Vui lòng đăng nhập hoặc thử lại.');
      }
    }
  }
}
