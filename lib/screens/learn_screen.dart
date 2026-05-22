import 'package:flutter/material.dart';
import '../services/course_service.dart';

class LearnScreen extends StatefulWidget {
  final int courseId;
  const LearnScreen({super.key, required this.courseId});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _courseData;
  List<dynamic> _allLessons = [];
  Map<String, dynamic>? _currentLesson;
  int _currentLessonId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await CourseService.getCourseContent(widget.courseId);
    if (data != null && mounted) {
      setState(() {
        _courseData = data;
        _allLessons = [];
        final chuongs = _courseData?['chuongs'] as List<dynamic>? ?? [];
        for (var ch in chuongs) {
          final baiHocs = ch['baiHocs'] as List<dynamic>? ?? [];
          _allLessons.addAll(baiHocs);
        }

        if (_allLessons.isNotEmpty) {
          // Tìm bài học đầu tiên chưa hoàn thành
          final firstIncomplete = _allLessons.firstWhere(
            (l) => l['daHoanThanh'] != true,
            orElse: () => _allLessons.first,
          );
          _currentLessonId = firstIncomplete['maBaiHoc'] ?? 0;
          _currentLesson = firstIncomplete;
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _selectLesson(dynamic lesson) {
    setState(() {
      _currentLessonId = lesson['maBaiHoc'] ?? 0;
      _currentLesson = lesson;
    });
  }

  void _completeLesson() async {
    if (_currentLesson == null) return;

    // Cập nhật UI ngay lập tức để tạo cảm giác mượt mà
    setState(() => _currentLesson!['daHoanThanh'] = true);

    final res = await CourseService.completeLesson(_currentLessonId);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Đã hoàn thành bài học!'),
          backgroundColor: Colors.green,
        ),
      );

      if (res['phanTramTienDo'] != null) {
        setState(() => _courseData?['phanTramTienDo'] = res['phanTramTienDo']);
      }

      // Tự động chuyển bài
      final idx = _allLessons.indexWhere(
        (l) => l['maBaiHoc'] == _currentLessonId,
      );
      if (idx >= 0 && idx < _allLessons.length - 1) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _selectLesson(_allLessons[idx + 1]);
        });
      } else {
        // Nếu đã xong 100%
        if ((_courseData?['phanTramTienDo'] ?? 0) >= 100 ||
            _allLessons.every((l) => l['daHoanThanh'] == true)) {
          _showCompletionDialog();
        }
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '🎉 Chúc mừng!',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn đã xuất sắc hoàn thành khóa học này. Hệ thống đã lưu lại tiến độ và chuẩn bị cấp chứng chỉ cho bạn.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Trở về trang chủ'),
          ),
        ],
      ),
    );
  }

  // Hàm loại bỏ thẻ HTML thô sơ
  String _stripHtml(String html) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return html.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    if (_courseData == null)
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không thể tải khóa học')),
      );

    final hasVideo =
        _currentLesson?['linkVideo'] != null &&
        _currentLesson!['linkVideo'].toString().isNotEmpty;
    final lessonTitle = _currentLesson?['lyThuyet'] != null
        ? _stripHtml(_currentLesson!['lyThuyet']).split('\n').first
        : 'Bài học $_currentLessonId';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _courseData?['tieuDe'] ?? 'Khóa học',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Tiến độ: ${_courseData?['phanTramTienDo']?.toStringAsFixed(0) ?? 0}%',
              style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KHU VỰC VIDEO/LÝ THUYẾT (Tạm giữ UI Placeholder nếu chưa cài video_player)
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: hasVideo
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white54,
                        size: 64,
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Text(
                          'Video link: ${_currentLesson?['linkVideo']}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.article,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bài học lý thuyết / Bài tập',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
          ),

          // TAB ĐIỀU HƯỚNG NỘI DUNG (Chuẩn Mobile)
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(text: 'Nội dung'),
                      Tab(text: 'Tổng quan'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCurriculumList(),
                        _buildOverviewTab(lessonTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumList() {
    final chuongs = _courseData?['chuongs'] as List<dynamic>? ?? [];
    return ListView.builder(
      itemCount: chuongs.length,
      itemBuilder: (context, index) {
        final ch = chuongs[index];
        final baiHocs = ch['baiHocs'] as List<dynamic>? ?? [];
        return ExpansionTile(
          initiallyExpanded: baiHocs.any(
            (l) => l['maBaiHoc'] == _currentLessonId,
          ),
          title: Text(
            'Chương ${index + 1}: ${ch['tieuDe']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          children: baiHocs.map((bh) {
            final isCurrent = bh['maBaiHoc'] == _currentLessonId;
            final isDone = bh['daHoanThanh'] == true;
            String text = bh['lyThuyet'] != null
                ? _stripHtml(bh['lyThuyet'])
                : 'Bài học';
            if (text.length > 45) text = '${text.substring(0, 45)}...';

            return ListTile(
              tileColor: isCurrent ? Colors.blue.withOpacity(0.08) : null,
              leading: Icon(
                isDone
                    ? Icons.check_circle
                    : (isCurrent
                          ? Icons.play_circle_fill
                          : Icons.radio_button_unchecked),
                color: isDone
                    ? Colors.green
                    : (isCurrent ? Colors.blue : Colors.grey),
              ),
              title: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.blue : Colors.black87,
                ),
              ),
              onTap: () => _selectLesson(bh),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOverviewTab(String title) {
    final theory = _currentLesson?['lyThuyet'] != null
        ? _stripHtml(_currentLesson!['lyThuyet'])
        : '';
    final exercise = _currentLesson?['baiTap'] != null
        ? _stripHtml(_currentLesson!['baiTap'])
        : '';
    final isDone = _currentLesson?['daHoanThanh'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (theory.isNotEmpty) ...[
            const Text(
              'Lý thuyết:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              theory,
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 16),
          ],
          if (exercise.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: const Border(
                  left: BorderSide(color: Colors.orange, width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bài tập:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise,
                    style: const TextStyle(height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: Icon(
                isDone ? Icons.check : Icons.school,
                color: Colors.white,
              ),
              label: Text(
                isDone ? 'Đã hoàn thành' : 'Đánh dấu hoàn thành',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? Colors.green : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isDone ? null : _completeLesson,
            ),
          ),
        ],
      ),
    );
  }
}
