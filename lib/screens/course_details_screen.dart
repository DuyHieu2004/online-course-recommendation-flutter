import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import 'learn_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final int courseId;
  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  Map<String, dynamic>? _courseData;
  List<dynamic> _reviews = [];
  List<dynamic> _similarCourses = [];
  List<dynamic> _recommendedCourses = [];

  bool _isLoading = true;
  bool _isLiked = false;
  bool _isEnrolled = false;
  bool _isExpired = false;
  bool _hasReviewed = false; // ✅ Đã đánh giá chưa (giống Angular)
  bool _isLoggedIn = false; // ✅ Đã đăng nhập chưa
  int? _currentUserId; // ✅ ID user hiện tại để check hasReviewed

  String _activeTab = 'overview'; // overview, content, reviews, instructor

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    // ✅ Kiểm tra trạng thái đăng nhập và lấy userId (giống Angular)
    final user = await AuthService.getCurrentUser();
    _isLoggedIn = user != null;
    _currentUserId = user?.userId;

    try {
      final results = await Future.wait([
        CourseService.getCourseDetails(widget.courseId),
        CourseService.getCourseReviews(widget.courseId),
        CourseService.getSimilarCourses(widget.courseId),
        CourseService.getRecommendedCourses(),
        CourseService.getBookmarks(),
        CourseService.getMyCourses(),
        // Lấy danh sách toàn bộ khóa học để Enrich Data
        CourseService.getCourses(pageSize: 100),
      ]);

      if (mounted) {
        setState(() {
          // 1. FIX LỖI TRỐNG DỮ LIỆU CHÍNH: Bóc tách key 'course' giống Angular
          final rawCourseRes = results[0] as Map<String, dynamic>?;
          _courseData = rawCourseRes?['course'] ?? rawCourseRes;

          _reviews = results[1] as List<dynamic>;

          // ✅ Check hasReviewed: so sánh userId trong reviews với user hiện tại (giống Angular checkIfUserReviewed)
          if (_isLoggedIn && _currentUserId != null) {
            _hasReviewed = _reviews.any((r) {
              final reviewerMap = r is Map ? r['nguoiDanhGia'] : null;
              if (reviewerMap is Map) {
                final id =
                    reviewerMap['maNguoiDung'] ?? reviewerMap['MaNguoiDung'];
                return id != null && id.toString() == _currentUserId.toString();
              }
              return false;
            });
          }

          final allCourses = results[6] as List<dynamic>;

          // HELPER AN TOÀN: Lấy ID từ bất kỳ Object hay Map nào
          int extractId(dynamic item) {
            if (item == null) return 0;
            if (item is Map) {
              final val =
                  item['courseId'] ??
                  item['CourseId'] ??
                  item['id'] ??
                  item['maKhoaHoc'];
              if (val != null) return int.tryParse(val.toString()) ?? 0;
              return 0;
            }
            try {
              return item.id ?? item.maKhoaHoc ?? item.courseId ?? 0;
            } catch (_) {
              return 0;
            }
          }

          // 2. Enrich Similar Courses (Khóa học liên quan)
          List<dynamic> rawSimilar = results[2] as List<dynamic>;
          _similarCourses = rawSimilar.map((item) {
            int targetId = extractId(item);
            var fullInfo = allCourses.cast<dynamic>().firstWhere(
              (c) => extractId(c) == targetId,
              orElse: () => null,
            );
            return fullInfo ?? item;
          }).toList();

          // 3. Enrich Recommended Courses (Học viên cũng quan tâm)
          List<dynamic> rawRecs = results[3] as List<dynamic>;
          _recommendedCourses = rawRecs
              .where((c) => extractId(c) != widget.courseId)
              .map((item) {
                int targetId = extractId(item);
                var fullInfo = allCourses.cast<dynamic>().firstWhere(
                  (c) => extractId(c) == targetId,
                  orElse: () => null,
                );
                return fullInfo ?? item;
              })
              .toList();

          // 4. Check Liked Status
          final bookmarks = results[4] as List<dynamic>;
          _isLiked = bookmarks.any((b) => extractId(b) == widget.courseId);

          // 5. Check Enrolled Status
          final myCourses = results[5] as List<dynamic>;
          final enrolledData = myCourses.firstWhere((c) {
            if (c is Map) {
              return (c['id'] == widget.courseId) ||
                  (c['khoaHoc']?['maKhoaHoc'] == widget.courseId);
            }
            try {
              return c.id == widget.courseId ||
                  c.khoaHoc?.maKhoaHoc == widget.courseId;
            } catch (_) {
              return false;
            }
          }, orElse: () => null);

          if (enrolledData != null) {
            _isEnrolled = true;
          }
        });
      }
    } catch (e) {
      print("Lỗi tải chi tiết: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePrimaryAction() async {
    if (_isEnrolled) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LearnScreen(courseId: widget.courseId),
        ),
      );
      return;
    }

    // SỬA ĐOẠN NÀY: Dùng addToCart thay vì buyCourse
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để mua!')),
      );
      return;
    }

    final res = await CourseService.addToCart(widget.courseId);
    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleLike() async {
    final success = await CourseService.toggleBookmark(widget.courseId);
    if (success && mounted) {
      setState(() => _isLiked = !_isLiked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLiked ? 'Đã thêm vào yêu thích' : 'Đã bỏ yêu thích'),
        ),
      );
    }
  }

  void _showRatingDialog() {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Viết đánh giá'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () =>
                          setDialogState(() => rating = index + 1.0),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Cảm nghĩ của bạn về khóa học...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await CourseService.rateCourse(
                widget.courseId,
                rating,
                commentController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Gửi đánh giá thành công!'
                          : 'Lỗi gửi đánh giá.',
                    ),
                  ),
                );
                if (success) {
                  setState(
                    () => _hasReviewed = true,
                  ); // ✅ Ẩn form sau khi gửi (giống Angular)
                  _loadAllData();
                }
              }
            },
            child: const Text('Gửi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI BUIDLERS ---

  Widget _buildOverviewTab() {
    final desc = _courseData!['moTa'] ?? 'Chưa có thông tin mô tả chi tiết.';
    final skills = _courseData!['kiNang']?.toString().split(',') ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Về khóa học này',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
          ),

          if (skills.isNotEmpty && skills[0].trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Kỹ năng bạn sẽ đạt được',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map<Widget>(
                    (s) => Chip(
                      avatar: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      label: Text(s.trim()),
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurriculumTab() {
    final chuongs = _courseData!['chuongs'] as List<dynamic>? ?? [];
    if (chuongs.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Chưa có nội dung bài học.')),
      );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chuongs.length,
      itemBuilder: (context, index) {
        final chuong = chuongs[index];
        final baiHocs = chuong['baiHocs'] as List<dynamic>? ?? [];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            title: Text(
              'Chương ${index + 1}: ${chuong['tieuDe'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${baiHocs.length} bài học',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            children: baiHocs.map((bh) {
              final isVideo =
                  bh['linkVideo'] != null &&
                  bh['linkVideo'].toString().isNotEmpty;
              return ListTile(
                leading: Icon(
                  isVideo ? Icons.play_circle_fill : Icons.article,
                  color: isVideo ? Colors.blue : Colors.orange,
                ),
                title: Text(
                  bh['lyThuyet'] ?? 'Bài học',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                dense: true,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    final avgRating =
        double.tryParse('${_courseData!['tbdanhGia'] ?? 0}') ?? 0.0;
    final totalReviews = _courseData!['soLuongDanhGia'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. RATING SUMMARY (stars động theo điểm thực, giống Angular) ──
          if (_reviews.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.indigo.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5B63D3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Stars theo đúng điểm số (không phải full 5 sao cứng)
                      Row(
                        children: List.generate(5, (i) {
                          if (i < avgRating.floor()) {
                            return const Icon(
                              Icons.star,
                              color: Color(0xFFFCCC29),
                              size: 22,
                            );
                          } else if (i < avgRating &&
                              avgRating - avgRating.floor() >= 0.5) {
                            return const Icon(
                              Icons.star_half,
                              color: Color(0xFFFCCC29),
                              size: 22,
                            );
                          } else {
                            return Icon(
                              Icons.star_border,
                              color: Colors.grey.shade300,
                              size: 22,
                            );
                          }
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalReviews đánh giá',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ── 2. TRẠNG THÁI FORM ĐÁNH GIÁ (logic 3 nhánh giống Angular) ──

          // Nhánh A: Đã đăng nhập + đã mua + CHƯA đánh giá → Hiển thị nút viết đánh giá
          if (_isLoggedIn && _isEnrolled && !_hasReviewed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Color(0xFF5B63D3)),
                      SizedBox(width: 6),
                      Text(
                        'Viết đánh giá của bạn',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Mở form đánh giá'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        side: const BorderSide(color: Color(0xFF1E88E5)),
                      ),
                      onPressed: _showRatingDialog,
                    ),
                  ),
                ],
              ),
            ),

          // Nhánh B: Đã đăng nhập + đã mua + ĐÃ đánh giá → Thông báo xanh (giống Angular)
          if (_isLoggedIn && _isEnrolled && _hasReviewed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn đã đánh giá khóa học này rồi. Cảm ơn bạn!',
                      style: TextStyle(color: Colors.green, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Nhánh C: Đã đăng nhập nhưng CHƯA mua → Nhắc mua (giống Angular)
          if (_isLoggedIn && !_isEnrolled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn cần mua khóa học này trước khi có thể đánh giá.',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Nhánh D: Chưa đăng nhập → Nhắc đăng nhập (giống Angular)
          if (!_isLoggedIn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.login, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đăng nhập để đánh giá khóa học này.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // ── 3. DANH SÁCH ĐÁNH GIÁ ──
          const Text(
            'Đánh giá từ học viên',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Trạng thái trống
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có đánh giá nào. Hãy là người đầu tiên!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),

          // Danh sách review (thêm avatar màu động + ngày, giống Angular)
          ..._reviews.map((rv) {
            final reviewerName =
                rv['nguoiDanhGia']?['ten'] as String? ?? 'Ẩn danh';
            final rating = (rv['rating'] ?? 5) as num;
            final comment = rv['binhLuan'] as String? ?? '';
            final dateStr = rv['ngayDanhGia'] as String?;
            String? formattedDate;
            if (dateStr != null) {
              try {
                final dt = DateTime.parse(dateStr);
                formattedDate =
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
              } catch (_) {}
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // ✅ Avatar màu ngẫu nhiên theo tên (giống Angular getAvatarColor)
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getAvatarColor(reviewerName),
                        child: Text(
                          _getInitials(reviewerName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviewerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                // ✅ Stars theo rating thực của từng review
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: i < rating.round()
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                    size: 14,
                                  ),
                                ),
                                // ✅ Ngày đánh giá (giống Angular)
                                if (formattedDate != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      comment,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Người dùng không để lại bình luận.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ✅ Avatar màu ngẫu nhiên theo tên (giống Angular getAvatarColor)
  Color _getAvatarColor(String? name) {
    if (name == null || name.isEmpty) return Colors.blueGrey;
    final colors = [
      Colors.red.shade400,
      Colors.amber.shade600,
      Colors.green.shade500,
      Colors.blue.shade500,
      Colors.indigo.shade400,
      Colors.purple.shade400,
      Colors.pink.shade400,
    ];
    int hash = 0;
    for (final ch in name.runes) {
      hash = ch + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  // ✅ Lấy chữ viết tắt từ tên (giống Angular getInitials)
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'HV';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildInstructorTab() {
    final giangViens = _courseData!['giangVien'] as List<dynamic>? ?? [];
    if (giangViens.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('Thông tin giảng viên đang cập nhật.')),
      );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: giangViens.length,
      itemBuilder: (context, index) {
        final gv = giangViens[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: gv['linkAnhDaiDien'] != null
                      ? NetworkImage(gv['linkAnhDaiDien'])
                      : null,
                  child: gv['linkAnhDaiDien'] == null
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gv['ten'] ?? 'Giảng viên',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chuyên gia / Giảng viên',
                        style: TextStyle(
                          color: Color(0xFF1E88E5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gv['tieuSu'] ?? 'Chưa có tiểu sử.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseHorizontalList(String title, List<dynamic> courses) {
    if (courses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final c = courses[index];

              // 1. BIẾN CHỨA DỮ LIỆU AN TOÀN
              String imageUrl = '';
              String cTitle = 'Đang cập nhật...';
              dynamic price = 0;
              int id = 0;

              // 2. TÁCH DỮ LIỆU DỰA TRÊN KIỂU DỮ LIỆU (Map hoặc Object)
              if (c is Map) {
                // Xử lý nếu data từ API trả về dạng Map thô
                imageUrl =
                    c['image'] ??
                    c['imageUrl'] ??
                    c['anhUrl'] ??
                    c['Image'] ??
                    '';
                cTitle = c['title'] ?? c['tieuDe'] ?? c['Title'] ?? 'Khóa học';
                price = c['price'] ?? c['giaGoc'] ?? c['Price'] ?? 0;
                id =
                    c['id'] ??
                    c['maKhoaHoc'] ??
                    c['CourseId'] ??
                    c['courseId'] ??
                    0;
              } else {
                // Xử lý nếu data đã được parse thành Model Object (ApiCourse, RecommendedCourse)
                // Dùng try-catch để bẫy lỗi NoSuchMethodError
                try {
                  id = c.id ?? c.maKhoaHoc ?? c.courseId ?? 0;
                } catch (_) {}
                try {
                  imageUrl = c.image ?? c.imageUrl ?? c.anhUrl ?? '';
                } catch (_) {}
                try {
                  cTitle = c.title ?? c.tieuDe ?? 'Khóa học';
                } catch (_) {}
                try {
                  price = c.price ?? c.originalPrice ?? c.giaGoc ?? 0;
                } catch (_) {}
              }

              // Xử lý ID dạng chuỗi (Neo4j đôi khi trả về String)
              if (id == 0 && c is Map && c['courseId'] != null) {
                id = int.tryParse(c['courseId'].toString()) ?? 0;
              }

              return Container(
                width: 160,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (id != 0) {
                        Navigator.pushReplacement(
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
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            color: Colors.blue.shade50,
                            image: imageUrl.length > 5
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl.length <= 5
                              ? const Center(
                                  child: Icon(
                                    Icons.school,
                                    color: Colors.blueGrey,
                                  ),
                                )
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                price == 0 ? 'Miễn phí' : '${price}đ',
                                style: const TextStyle(
                                  color: Color(0xFF1E88E5),
                                  fontWeight: FontWeight.bold,
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
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_courseData == null)
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy thông tin khóa học.')),
      );

    final data = _courseData!;
    final price = data['giaGoc'] ?? 0;
    // Xử lý giá khuyến mãi nếu có
    final finalPrice =
        (data['khuyenMai'] != null && data['khuyenMai']['phanTramGiam'] != null)
        ? price * (1 - data['khuyenMai']['phanTramGiam'] / 100)
        : price;

    final imageUrl = data['anhUrl'];
    final categoryName = data['theLoai']?['ten'] ?? 'Khóa học';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chi tiết khóa học',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
            ),
            onPressed: _toggleLike,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Image
            if (imageUrl != null && imageUrl.toString().startsWith('http'))
              Image.network(imageUrl, height: 220, fit: BoxFit.cover)
            else
              Container(
                height: 220,
                color: Colors.blue.shade900,
                child: const Center(
                  child: Icon(Icons.school, size: 80, color: Colors.white24),
                ),
              ),

            // 2. Tiêu đề & Meta Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        color: Color(0xFF1E88E5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['tieuDe'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${data['tbdanhGia'] ?? '0.0'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${data['soLuongDanhGia'] ?? 0} đánh giá)',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.people, color: Colors.grey, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${data['soHocVien'] ?? 0} học viên',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // 3. Tabs Component (Custom Menu)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTabButton('Tổng quan', 'overview'),
                  _buildTabButton('Nội dung', 'content'),
                  _buildTabButton('Giảng viên', 'instructor'),
                  _buildTabButton('Đánh giá', 'reviews'),
                ],
              ),
            ),
            const Divider(height: 1),

            // 4. Tab Content
            if (_activeTab == 'overview') _buildOverviewTab(),
            if (_activeTab == 'content') _buildCurriculumTab(),
            if (_activeTab == 'instructor') _buildInstructorTab(),
            if (_activeTab == 'reviews') _buildReviewsTab(),

            const SizedBox(height: 24),
            const Divider(thickness: 4, color: Color(0xFFF5F5F5)),

            // 5. Recommendations Sections
            _buildCourseHorizontalList('Khóa học liên quan', _similarCourses),
            _buildCourseHorizontalList(
              'Học viên cũng quan tâm',
              _recommendedCourses,
            ),
            const SizedBox(height: 40), // Spacing for bottom bar
          ],
        ),
      ),

      // 6. Sticky Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEnrolled) ...[
                      Text(
                        finalPrice == 0 ? 'Miễn phí' : '${finalPrice.toInt()}đ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      if (price > finalPrice)
                        Text(
                          '${price.toInt()}đ',
                          style: const TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ] else ...[
                      const Text(
                        'Trạng thái',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Text(
                        'Đã sở hữu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handlePrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEnrolled
                          ? Colors.green
                          : const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isEnrolled ? 'Vào học ngay' : 'Thêm vào giỏ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, String tabId) {
    final isActive = _activeTab == tabId;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF1E88E5) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF1E88E5) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
