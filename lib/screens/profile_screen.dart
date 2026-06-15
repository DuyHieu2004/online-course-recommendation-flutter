import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import '../models/user_profile_model.dart';
import 'order_history_screen.dart';
import '../api_constants.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'learn_screen.dart';
import 'certificate_screen.dart';

// ─────────────────────────────────────────────
// Lightweight certificate model (inline)
// ─────────────────────────────────────────────
class _Certificate {
  final int id;
  final int courseId;
  final String courseName;
  final String issuedDate;
  final String? thumbnailUrl;

  _Certificate({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.issuedDate,
    this.thumbnailUrl,
  });

  factory _Certificate.fromJson(Map<String, dynamic> json) {
    // API thường lồng thông tin vào object khoaHoc
    final khoaHoc = json['khoaHoc'] ?? json['course'] ?? json;

    return _Certificate(
      id: json['maChungChi'] ?? json['maCertificate'] ?? json['id'] ?? 0,
      courseId: khoaHoc['maKhoaHoc'] ?? khoaHoc['id'] ?? json['courseId'] ?? 0,
      courseName:
          khoaHoc['tieuDe'] ??
          khoaHoc['title'] ??
          json['tenKhoaHoc'] ??
          json['courseName'] ??
          'Chứng chỉ khóa học',
      issuedDate: json['ngayPhat'] ?? json['ngayCap'] ?? json['issuedDate'] ?? '',
      thumbnailUrl:
          khoaHoc['anhUrl'] ??
          khoaHoc['image'] ??
          json['anhBia'] ??
          json['thumbnailUrl'],
    );
  }
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────
  UserProfile? _user;
  List<dynamic> _allCourses = [];
  List<_Certificate> _certificates = [];
  bool _loadingCourses = true;
  bool _loadingCerts = true;
  late TabController _tabController;

  // Filter / search
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Colours (reuse app palette) ───────────
  static const Color _yellow = Color(0xFFFFCC33);
  static const Color _blue = Color(0xFF1E88E5);
  static const Color _bg = Color(0xFFF5F6FA);
  static const Color _card = Colors.white;
  static const Color _green = Color(0xFF43A047);
  static const Color _orange = Color(0xFFFB8C00);

  // ── Lifecycle ─────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────
  Future<void> _loadAll() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) setState(() => _user = user);
    await Future.wait([_loadCourses(), _loadCertificates()]);
  }

  Future<void> _loadCourses() async {
    setState(() => _loadingCourses = true);
    final courses = await CourseService.getMyCourses();
    if (mounted) {
      setState(() {
        _allCourses = courses;
        _loadingCourses = false;
      });
    }
  }

  Future<void> _loadCertificates() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _loadingCerts = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Learning/certificates'),
        headers: {'Authorization': 'Bearer ${user.token}'},
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            final parsedCerts = data.map((j) => _Certificate.fromJson(j)).toList();
            
            // Lọc trùng lặp chứng chỉ (vì lỗi data cũ có thể tạo ra hàng trăm chứng chỉ giống nhau)
            final Map<String, _Certificate> uniqueCerts = {};
            for (var c in parsedCerts) {
              // Bỏ qua các chứng chỉ bị lỗi (không có tên khóa học)
              if (c.courseName.isNotEmpty && c.courseName != 'Chứng chỉ khóa học') {
                uniqueCerts[c.courseName] = c;
              }
            }
            
            _certificates = uniqueCerts.values.toList();
            _loadingCerts = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingCerts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCerts = false);
    }
  }

  // ── CÁC HÀM BẪY LỖI MAP AN TOÀN ─────────────────────────
  bool _isCourseCompleted(dynamic course) {
    final Map<String, dynamic> c = course is Map
        ? course as Map<String, dynamic>
        : {};
    if (c['hoanThanh'] == true || c['isCompleted'] == true) return true;

    num progress = c['phanTramTienDo'] ?? c['progress'] ?? c['tienDo'] ?? 0;
    return progress >= 100;
  }

  bool _matchSearch(dynamic course) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();

    final Map<String, dynamic> c = course is Map
        ? course as Map<String, dynamic>
        : {};
    final khoaHoc = c['khoaHoc'] ?? c['course'] ?? c;

    String title =
        (khoaHoc['tieuDe'] ?? khoaHoc['title'] ?? c['tenKhoaHoc'] ?? '')
            .toString()
            .toLowerCase();
    String instructor =
        (khoaHoc['giangVien'] ??
                khoaHoc['instructor'] ??
                c['tenGiangVien'] ??
                '')
            .toString()
            .toLowerCase();

    return title.contains(q) || instructor.contains(q);
  }

  // ── Computed lists ─────────────────────────
  List<dynamic> get _inProgress => _allCourses
      .where((c) => !_isCourseCompleted(c))
      .where((c) => _matchSearch(c))
      .toList();

  List<dynamic> get _completed => _allCourses
      .where((c) => _isCourseCompleted(c))
      .where((c) => _matchSearch(c))
      .toList();

  // ── Stats ──────────────────────────────────
  int get _totalEnrolled => _allCourses.length;
  int get _totalCompleted =>
      _allCourses.where((c) => _isCourseCompleted(c)).length;
  int get _totalInProgress =>
      _allCourses.where((c) => !_isCourseCompleted(c)).length;

  // ── Actions ───────────────────────────────
  void _logout() async {
    await AuthService.clearAuthData();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SettingsSheet(
        onChangePassword: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        },
        onLogout: () {
          Navigator.pop(context);
          _logout();
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverHeader()],
        body: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCourseTab(
                    _inProgress,
                    emptyMsg: 'Chưa có khóa học nào đang học',
                    emptyIcon: Icons.play_circle_outline,
                  ),
                  _buildCourseTab(
                    _completed,
                    emptyMsg: 'Chưa hoàn thành khóa học nào',
                    emptyIcon: Icons.check_circle_outline,
                  ),
                  _buildCertificatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SLIVER HEADER — user card + stats
  // ─────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _yellow,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black87),
          onPressed: _showSettingsSheet,
        ),
      ],
      title: const Text(
        'Học của tôi',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user?.name ?? '...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _user?.email ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TÌM HÀM _buildStatsRow() VÀ _buildStatItem() VÀ THAY THẾ TOÀN BỘ THÀNH:
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Giúp căn chỉnh không bị tràn đáy
        children: [
          _buildStatItem(
            _totalEnrolled.toString(),
            'Đã đăng ký',
            Icons.school_outlined,
            _blue,
          ),
          _buildStatDivider(),
          _buildStatItem(
            _totalInProgress.toString(),
            'Đang học',
            Icons.play_circle_outline,
            _orange,
          ),
          _buildStatDivider(),
          _buildStatItem(
            _totalCompleted.toString(),
            'Hoàn thành',
            Icons.check_circle_outline,
            _green,
          ),
          _buildStatDivider(),
          _buildStatItem(
            _certificates.length.toString(),
            'Chứng chỉ',
            Icons.workspace_premium_outlined,
            const Color(0xFF8E24AA),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Rất quan trọng để không bị overflow
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20), // Giảm size icon một chút
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() =>
      Container(height: 36, width: 1, color: Colors.grey.shade200);

  // ─────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm khóa học...',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black38),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.black38,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicator: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.all(4),
          tabs: [
            Tab(
              child: Text(
                'Đang học (${_totalInProgress})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Tab(
              child: Text(
                'Xong (${_totalCompleted})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Tab(
              child: Text(
                'Chứng chỉ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // COURSE TAB
  // ─────────────────────────────────────────
  Widget _buildCourseTab(
    List<dynamic> courses, {
    required String emptyMsg,
    required IconData emptyIcon,
  }) {
    if (_loadingCourses) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (courses.isEmpty) {
      return _buildEmpty(emptyIcon, emptyMsg);
    }
    return RefreshIndicator(
      color: _blue,
      onRefresh: _loadCourses,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: courses.length,
        itemBuilder: (_, i) => _CourseCard(course: courses[i]),
      ),
    );
  }

  // ─────────────────────────────────────────
  // CERTIFICATES TAB
  // ─────────────────────────────────────────
  Widget _buildCertificatesTab() {
    if (_loadingCerts) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (_certificates.isEmpty) {
      return _buildEmpty(
        Icons.workspace_premium_outlined,
        'Hoàn thành khóa học để nhận chứng chỉ',
      );
    }
    return RefreshIndicator(
      color: _blue,
      onRefresh: _loadCertificates,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _certificates.length,
        itemBuilder: (_, i) => _CertificateCard(
          cert: _certificates[i],
          userName: _user?.name ?? 'Học viên',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────
  Widget _buildEmpty(IconData icon, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.black12),
            const SizedBox(height: 16),
            Text(
              msg,
              style: const TextStyle(color: Colors.black38, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Course Card Widget
// ─────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final dynamic course;
  const _CourseCard({required this.course});

  static const Color _blue = Color(0xFF1E88E5);
  static const Color _green = Color(0xFF43A047);

  @override
  Widget build(BuildContext context) {
    // Bóc tách JSON an toàn (Xử lý object lồng nhau)
    final Map<String, dynamic> c = course is Map
        ? course as Map<String, dynamic>
        : {};
    final khoaHoc =
        c['khoaHoc'] ?? c['course'] ?? c; // Fallback nếu không có nested object

    int courseId =
        khoaHoc['maKhoaHoc'] ??
        khoaHoc['id'] ??
        c['courseId'] ??
        c['CourseId'] ??
        0;
    String title =
        khoaHoc['tieuDe'] ??
        khoaHoc['title'] ??
        c['tenKhoaHoc'] ??
        'Chưa có tên khóa học';
    String imageUrl =
        khoaHoc['anhUrl'] ??
        khoaHoc['image'] ??
        khoaHoc['imageUrl'] ??
        c['anhBia'] ??
        '';
    String instructor =
        khoaHoc['giangVien'] ??
        khoaHoc['instructor'] ??
        c['tenGiangVien'] ??
        'Đang cập nhật';

    double progress = 0;
    if (c['phanTramTienDo'] != null)
      progress = (c['phanTramTienDo'] as num).toDouble();
    else if (c['progress'] != null)
      progress = (c['progress'] as num).toDouble();
    progress = progress.clamp(0, 100);

    bool isCompleted =
        c['hoanThanh'] == true || c['isCompleted'] == true || progress >= 100;

    int doneLessons = c['soLuongBaiHocDaHoan'] ?? c['completedLessons'] ?? 0;
    int totalLessons =
        khoaHoc['soLuongBaiHoc'] ?? khoaHoc['modules'] ?? c['tongBaiHoc'] ?? 0;

    final progressColor = isCompleted ? _green : _blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // CHUYỂN HƯỚNG SANG MÀN HÌNH HỌC TẬP THỰC TẾ
          if (courseId > 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LearnScreen(courseId: courseId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi: Không tìm thấy ID khóa học')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 88,
                  height: 68,
                  child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instructor,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation(
                                    progressColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    totalLessons == 0
                                        ? 'Đang cập nhật'
                                        : '$doneLessons/$totalLessons bài học',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black38,
                                    ),
                                  ),
                                  Text(
                                    '${progress.toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: progressColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: _green,
                    size: 18,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.play_arrow, color: _blue, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    color: const Color(0xFFF0F4FF),
    child: const Icon(
      Icons.play_lesson_outlined,
      color: Color(0xFF1E88E5),
      size: 30,
    ),
  );
}

// ─────────────────────────────────────────────
// Certificate Card Widget
// ─────────────────────────────────────────────
class _CertificateCard extends StatelessWidget {
  final _Certificate cert;
  final String userName;
  const _CertificateCard({required this.cert, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D5FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 26,
          ),
        ),
        title: Text(
          cert.courseName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: Colors.black38,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(cert.issuedDate),
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Xem',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8E24AA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CertificateScreen(
                userName: userName,
                courseName: cert.courseName,
                issuedDate: _formatDate(cert.issuedDate),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return 'Đang cập nhật';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw; // Fallback nếu chuỗi ngày tháng ko chuẩn format
    }
  }
}

// ─────────────────────────────────────────────
// Settings Bottom Sheet
// ─────────────────────────────────────────────
class _SettingsSheet extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const _SettingsSheet({
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Cài đặt',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _sheetItem(
              Icons.person_outline,
              'Chỉnh sửa hồ sơ',
              Colors.black87,
              () => Navigator.pop(context),
            ),
            const Divider(height: 1, indent: 52),
            _sheetItem(
              Icons.receipt_long_outlined,
              'Lịch sử mua hàng',
              Colors.black87,
              () {
                Navigator.pop(context); // Đóng BottomSheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 52),
            _sheetItem(
              Icons.lock_outline,
              'Đổi mật khẩu',
              Colors.black87,
              onChangePassword,
            ),
            const Divider(height: 1, indent: 52),
            _sheetItem(
              Icons.settings_outlined,
              'Cài đặt thông báo',
              Colors.black87,
              () => Navigator.pop(context),
            ),
            const Divider(height: 1, indent: 52),
            _sheetItem(
              Icons.help_outline,
              'Trợ giúp & Hỗ trợ',
              Colors.black87,
              () => Navigator.pop(context),
            ),
            const Divider(height: 1, indent: 52),
            _sheetItem(Icons.logout, 'Đăng xuất', Colors.red, onLogout),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.black26,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
