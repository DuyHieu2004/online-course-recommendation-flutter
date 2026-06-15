import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
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

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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
          final firstIncomplete = _allLessons.firstWhere(
            (l) => l['daHoanThanh'] != true,
            orElse: () => _allLessons.first,
          );
          _currentLessonId = firstIncomplete['maBaiHoc'] ?? 0;
          _currentLesson = firstIncomplete;
        }
        _isLoading = false;
      });
      _initVideo();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _selectLesson(dynamic lesson) {
    setState(() {
      _currentLessonId = lesson['maBaiHoc'] ?? 0;
      _currentLesson = lesson;
    });
    _initVideo();
  }

  Future<void> _initVideo() async {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;

    final linkVideo = _currentLesson?['linkVideo']?.toString();
    if (linkVideo != null && linkVideo.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(linkVideo));
      try {
        await _videoPlayerController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
        if (mounted) setState(() {});
      } catch (e) {
        print("Error initializing video: $e");
      }
    }
  }

  void _completeLesson() async {
    if (_currentLesson == null) return;

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

      final idx = _allLessons.indexWhere(
        (l) => l['maBaiHoc'] == _currentLessonId,
      );
      if (idx >= 0 && idx < _allLessons.length - 1) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _selectLesson(_allLessons[idx + 1]);
        });
      } else {
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
    final lessonTitle = _currentLesson?['lyThuyet'] != null && _currentLesson!['lyThuyet'].toString().isNotEmpty
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
          // KHU VỰC VIDEO/LÝ THUYẾT
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: _chewieController != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : (hasVideo
                    ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
                      )),
          ),

          // TAB ĐIỀU HƯỚNG NỘI DUNG
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

  bool _isChapterPassed(dynamic ch) {
    final baiHocs = ch['baiHocs'] as List<dynamic>? ?? [];
    if (baiHocs.isEmpty) return true;
    
    // Tìm bài kiểm tra trong chương (tìm từ dưới lên)
    for (var l in baiHocs.reversed) {
       String baiTap = l['baiTap']?.toString() ?? '';
       if (baiTap.contains('"isQuiz"')) {
          return l['daHoanThanh'] == true;
       }
    }
    // Nếu không có bài kiểm tra, kiểm tra bài học cuối cùng
    return baiHocs.last['daHoanThanh'] == true;
  }

  Widget _buildCurriculumList() {
    final chuongs = _courseData?['chuongs'] as List<dynamic>? ?? [];
    return ListView.builder(
      itemCount: chuongs.length,
      itemBuilder: (context, index) {
        final ch = chuongs[index];
        final baiHocs = ch['baiHocs'] as List<dynamic>? ?? [];
        
        // Kiểm tra xem chương này có được mở khóa không
        bool isChapterUnlocked = true;
        for (int i = 0; i < index; i++) {
          if (!_isChapterPassed(chuongs[i])) {
            isChapterUnlocked = false;
            break;
          }
        }

        return ExpansionTile(
          initiallyExpanded: baiHocs.any(
            (l) => l['maBaiHoc'] == _currentLessonId,
          ),
          title: Text(
            'Chương ${index + 1}: ${ch['tieuDe']}',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 14,
              color: isChapterUnlocked ? Colors.black87 : Colors.grey,
            ),
          ),
          trailing: isChapterUnlocked 
              ? const Icon(Icons.expand_more)
              : const Icon(Icons.lock, color: Colors.grey),
          children: baiHocs.map((bh) {
            final isCurrent = bh['maBaiHoc'] == _currentLessonId;
            final isDone = bh['daHoanThanh'] == true;
            
            bool isUnlocked = isChapterUnlocked;

            String text = bh['lyThuyet'] != null && bh['lyThuyet'].toString().isNotEmpty
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
                          : (isUnlocked ? Icons.radio_button_unchecked : Icons.lock)),
                color: isDone
                    ? Colors.green
                    : (isCurrent ? Colors.blue : (isUnlocked ? Colors.grey : Colors.grey.shade400)),
              ),
              title: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.blue : (isUnlocked ? Colors.black87 : Colors.grey),
                ),
              ),
              onTap: isUnlocked ? () => _selectLesson(bh) : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bạn cần hoàn thành bài kiểm tra của chương trước để mở khóa chương này!')),
                );
              },
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
    final rawExercise = _currentLesson?['baiTap']?.toString() ?? '';
    final linkTaiLieu = _currentLesson?['linkTaiLieu']?.toString();
    final isDone = _currentLesson?['daHoanThanh'] == true;

    Map<String, dynamic>? quizData;
    String cleanExercise = _stripHtml(rawExercise);

    if (rawExercise.trim().startsWith('{') && rawExercise.contains('"isQuiz"')) {
      try {
        quizData = json.decode(rawExercise);
        cleanExercise = ''; 
      } catch (e) {
        // ignore
      }
    }

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
          if (linkTaiLieu != null && linkTaiLieu.isNotEmpty) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Xem Tài Liệu (PDF)'),
              onPressed: () async {
                final url = Uri.parse(linkTaiLieu);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở tài liệu')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
          ],
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
          if (quizData != null) ...[
             QuizWidget(
               quizData: quizData,
               onPassed: () {
                 if (!isDone) _completeLesson();
               },
             ),
             const SizedBox(height: 24),
          ] else if (cleanExercise.isNotEmpty) ...[
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
                    cleanExercise,
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

class QuizWidget extends StatefulWidget {
  final Map<String, dynamic> quizData;
  final VoidCallback onPassed;

  const QuizWidget({Key? key, required this.quizData, required this.onPassed}) : super(key: key);

  @override
  _QuizWidgetState createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  Map<int, int> _selectedAnswers = {};
  bool _submitted = false;
  int _score = 0;

  void _submit() {
    int score = 0;
    List questions = widget.quizData['questions'] ?? [];
    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i]['correctIdx']) {
        score += 1;
      }
    }
    setState(() {
      _score = score;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List questions = widget.quizData['questions'] ?? [];
    int passingScore = widget.quizData['passingScore'] ?? 80;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.quiz, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bài kiểm tra trắc nghiệm (Điểm qua môn: $passingScore%)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(questions.length, (index) {
          var q = questions[index];
          List options = q['options'] ?? [];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Câu ${index + 1}: ${q['text']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(options.length, (optIdx) {
                    bool isCorrect = optIdx == q['correctIdx'];
                    bool isSelected = _selectedAnswers[index] == optIdx;
                    Color? textColor = Colors.black87;
                    if (_submitted) {
                      if (isCorrect) textColor = Colors.green;
                      else if (isSelected && !isCorrect) textColor = Colors.red;
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _submitted && isCorrect
                              ? Colors.green
                              : _submitted && isSelected && !isCorrect
                                  ? Colors.red
                                  : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: _submitted && isCorrect
                            ? Colors.green.shade50
                            : _submitted && isSelected && !isCorrect
                                ? Colors.red.shade50
                                : Colors.transparent,
                      ),
                      child: RadioListTile<int>(
                        title: Text(
                          options[optIdx].toString(),
                          style: TextStyle(color: textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                        value: optIdx,
                        groupValue: _selectedAnswers[index],
                        activeColor: Colors.blue,
                        onChanged: _submitted ? null : (val) {
                          setState(() {
                            _selectedAnswers[index] = val!;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
        if (_submitted)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: (_score / questions.length * 100) >= passingScore ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_score / questions.length * 100) >= passingScore ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  (_score / questions.length * 100) >= passingScore ? Icons.check_circle : Icons.cancel,
                  color: (_score / questions.length * 100) >= passingScore ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Điểm của bạn: ${(_score / questions.length * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: (_score / questions.length * 100) >= passingScore ? Colors.green : Colors.red,
                        ),
                      ),
                      if ((_score / questions.length * 100) < passingScore)
                        const Text('Bạn chưa đạt điểm tối thiểu. Vui lòng thử lại!', style: TextStyle(color: Colors.red)),
                      if ((_score / questions.length * 100) >= passingScore)
                        const Text('Tuyệt vời! Bạn đã vượt qua bài kiểm tra.', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submitted 
                ? (((_score / questions.length) * 100) >= passingScore 
                    ? () { widget.onPassed(); } 
                    : () { 
                        setState(() {
                          _submitted = false;
                          _selectedAnswers.clear();
                          _score = 0;
                        });
                      })
                : (_selectedAnswers.length == questions.length ? _submit : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: _submitted 
                  ? (((_score / questions.length) * 100) >= passingScore ? Colors.green : Colors.orange) 
                  : Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _submitted 
                  ? (((_score / questions.length) * 100) >= passingScore ? 'Hoàn thành bài học & Tiếp tục' : 'Làm lại bài kiểm tra')
                  : 'Nộp bài',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
