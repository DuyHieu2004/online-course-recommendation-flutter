import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../utils/toast_utils.dart';
import 'pdf_viewer_screen.dart';
import 'quiz_screen.dart';
import '../api_constants.dart';

class LearningScreen extends StatefulWidget {
  final int courseId;
  const LearningScreen({super.key, required this.courseId});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  Map<String, dynamic>? _learningData;
  bool _isLoading = true;
  Map<String, dynamic>? _selectedLesson;
  double _progress = 0.0;
  String _userName = 'Học viên';

  // Video Controllers
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  double _maxTimeWatched = 0;
  bool _isLockingWarningShown = false;
  String _userRole = 'HocVien';
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveProgress();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController = null;
    _videoPlayerController = null;
    _chewieController = null;
  }

  void _loadContent() async {
    final data = await CourseService.getCourseContent(widget.courseId);
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _learningData = data;
        _userName = user?.name ?? 'Học viên';
        _userRole = user?.role ?? 'HocVien';
        _isLoading = false;
        if (data != null) {
          _progress = (data['phanTramTienDo'] ?? 0.0).toDouble() / 100;
          if (_selectedLesson == null && data['chuongs'] != null && (data['chuongs'] as List).isNotEmpty) {
            final firstChapter = data['chuongs'][0];
            if (firstChapter['baiHocs'] != null && (firstChapter['baiHocs'] as List).isNotEmpty) {
              _onLessonSelected(firstChapter['baiHocs'][0]);
            }
          }
        }
      });
    }
  }

  void _onLessonSelected(Map<String, dynamic> lesson) {
    if (_selectedLesson?['maBaiHoc'] == lesson['maBaiHoc']) return;

    _saveProgress(); // Save previous lesson progress before switching

    setState(() {
      _selectedLesson = lesson;
      _disposeVideoControllers();
    });

    final String? videoUrl = lesson['linkVideo'];
    final double initialTime = (lesson['thoiGian'] ?? 0).toDouble();
    _maxTimeWatched = initialTime;
    _isLockingWarningShown = false;

    if (videoUrl != null && videoUrl.isNotEmpty) {
      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: YoutubePlayerFlags(
              autoPlay: false, 
              mute: false,
              startAt: initialTime.toInt(),
              enableCaption: false,
            ),
          )..addListener(_onYoutubeProgress)
           ..addListener(_onYoutubeRateChange);
        }
      } else {
        // Direct video link (Cloudinary, MP4, etc.)
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        _videoPlayerController!.initialize().then((_) {
          if (mounted) {
            _videoPlayerController!.addListener(_onVideoPlayerProgress);
            setState(() {
              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController!,
                autoPlay: false,
                looping: false,
                startAt: Duration(seconds: initialTime.toInt()),
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                allowPlaybackSpeedChanging: false, // User requested: Không cho phép chỉnh tốc độ
                placeholder: Container(color: Colors.black),
                errorBuilder: (context, errorMessage) {
                  return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
                },
              );
            });
          }
        });
      }
      
      // Start periodic saving
      _saveTimer?.cancel();
      _saveTimer = Timer.periodic(const Duration(seconds: 15), (timer) => _saveProgress());
    }
  }

  void _onYoutubeProgress() {
    if (_youtubeController == null) return;
    final currentTime = _youtubeController!.value.position.inSeconds.toDouble();
    _handleVideoProgress(currentTime);
  }

  void _onVideoPlayerProgress() {
    if (_videoPlayerController == null) return;
    final currentTime = _videoPlayerController!.value.position.inSeconds.toDouble();
    _handleVideoProgress(currentTime);
  }

  void _handleVideoProgress(double currentTime) {
    if (currentTime > _maxTimeWatched + 3) {
      // User tried to skip forward
      if (_youtubeController != null) {
        _youtubeController!.seekTo(Duration(seconds: _maxTimeWatched.toInt()));
      } else if (_videoPlayerController != null) {
        _videoPlayerController!.seekTo(Duration(seconds: _maxTimeWatched.toInt()));
      }
      
      if (!_isLockingWarningShown) {
        _isLockingWarningShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảnh báo: Bạn không được phép tua nhanh video! Vui lòng học tập nghiêm túc.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        ).closed.then((_) => _isLockingWarningShown = false);
      }
    } else {
      // Allow progress update if current time is ahead of max watched
      if (currentTime > _maxTimeWatched) {
        _maxTimeWatched = currentTime;
      }
    }
  }

  void _onYoutubeRateChange() {
    if (_youtubeController != null && _youtubeController!.value.playbackRate != 1.0) {
      _youtubeController!.setPlaybackRate(1.0);
      ToastUtils.showInfo('Tính năng thay đổi tốc độ bị vô hiệu hóa');
    }
  }

  void _saveProgress() {
    if (_selectedLesson == null) return;
    int currentTime = 0;
    if (_youtubeController != null) {
      currentTime = _youtubeController!.value.position.inSeconds;
    } else if (_videoPlayerController != null) {
      currentTime = _videoPlayerController!.value.position.inSeconds;
    }

    if (currentTime > 0) {
      CourseService.saveLessonTime(_selectedLesson!['maBaiHoc'], currentTime);
      // Update local data to keep sync
      _selectedLesson!['thoiGian'] = currentTime;
    }
  }

  bool _isLessonLocked(Map<String, dynamic> lesson) {
    if (_learningData == null) return true;
    final List chapters = _learningData!['chuongs'] ?? [];
    List allLessons = [];
    for (var ch in chapters) {
      allLessons.addAll(ch['baiHocs'] ?? []);
    }
    
    int index = allLessons.indexWhere((l) => l['maBaiHoc'] == lesson['maBaiHoc']);
    if (index <= 0) return false; // First lesson is never locked
    
    // Locked if previous lesson is not completed
    return !(allLessons[index - 1]['daHoanThanh'] ?? false);
  }

  void _completeLesson(int lessonId) async {
    final result = await CourseService.completeLesson(lessonId);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chúc mừng! Bạn đã hoàn thành bài học.')),
      );
      _loadContent();
    }
  }

  void _showRatingDialog() {
    double selectedRating = 5.0;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Đánh giá khóa học', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bạn cảm thấy khóa học này như thế nào?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập nhận xét của bạn (không bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await CourseService.rateCourse(
                      widget.courseId,
                      selectedRating,
                      reviewController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ToastUtils.showInfo('Cảm ơn bạn đã đánh giá khóa học!');
                      } else {
                        ToastUtils.showInfo('Có lỗi xảy ra khi gửi đánh giá.');
                      }
                    }
                  },
                  child: const Text('Gửi đánh giá'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openDocument(String? url, String title) async {
    if (url == null || url.isEmpty) return;

    String finalUrl = url;
    if (!finalUrl.startsWith('http')) {
      final baseUrlWithoutApi = ApiConstants.baseUrl.replaceAll('/api', '');
      finalUrl = '$baseUrlWithoutApi$finalUrl';
    }

    if (finalUrl.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(pdfUrl: finalUrl, title: title),
        ),
      );
    } else {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở tài liệu này.')),
          );
        }
      }
    }
  }

  void _showAnnouncements() async {
    final announcements = await CourseService.getCourseAnnouncements(widget.courseId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông báo từ giảng viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (announcements.isEmpty)
                const Center(child: Text('Chưa có thông báo nào.'))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: announcements.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = announcements[index];
                      String dateStr = '';
                      if (item['ngayTao'] != null) {
                        try {
                          final date = DateTime.parse(item['ngayTao']);
                          dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
                        } catch (e) {}
                      }

                      return ListTile(
                        leading: const Icon(Icons.campaign, color: Colors.blue),
                        title: Text(item['tieuDe'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dateStr.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              ),
                            Text(item['noiDung'] ?? ''),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_learningData == null) {
      return const Scaffold(body: Center(child: Text('Không thể tải nội dung học tập.')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_learningData!['tieuDe'] ?? 'Đang học', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.blue),
            onPressed: _showAnnouncements,
            tooltip: 'Thông báo khóa học',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPlayerArea(),
          _buildProgressBar(),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 3, child: _buildLessonContent()),
                const VerticalDivider(width: 1),
                Expanded(flex: 2, child: _buildCurriculum()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: _youtubeController != null
            ? YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.blue,
              )
            : (_chewieController != null
                ? Chewie(controller: _chewieController!)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_library, size: 50, color: Colors.white24),
                        const SizedBox(height: 8),
                        Text(
                          _selectedLesson?['linkVideo'] == null ? 'Không có video' : 'Đang tải video...',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiến độ học tập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: [
                  // Certificate viewing button (Only active when progress is 100%)
                  IconButton(
                    icon: Icon(
                      _progress >= 1.0 ? Icons.workspace_premium : Icons.workspace_premium_outlined, 
                      size: 24, 
                      color: _progress >= 1.0 ? Colors.blue.shade700 : Colors.grey
                    ),
                    onPressed: _progress >= 1.0 
                      ? () => _openCertificate()
                      : () => ToastUtils.showInfo('Bạn cần hoàn thành 100% khóa học để nhận chứng chỉ'),
                    tooltip: 'Xem chứng chỉ hoàn thành',
                   ),
                  if (_userRole == 'Admin')
                    IconButton(
                      icon: const Icon(Icons.image_search, color: Colors.blue),
                      onPressed: () {
                        // TODO: Implement change image
                        ToastUtils.showInfo('Tính năng thay đổi hình ảnh đang phát triển');
                      },
                      tooltip: 'Thay đổi hình ảnh khóa học',
                    ),
                  if (_progress >= 1.0)
                    TextButton.icon(
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.star, color: Colors.orange, size: 16),
                      label: const Text('Đánh giá', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                  else
                    Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    if (_selectedLesson == null) return const Center(child: Text('Hãy chọn bài học để bắt đầu.'));
    
    final bool isCompleted = _selectedLesson!['daHoanThanh'] ?? false;
    final String? theory = _selectedLesson!['lyThuyet'];
    final String? lessonTitle = _selectedLesson!['tieuDe'] ?? 'Bài học';
    final String? exercise = _selectedLesson!['baiTap'];
    final String? documentUrl = _selectedLesson!['linkTaiLieu'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(lessonTitle!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              if (_userRole == 'Admin')
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.blue),
                  onPressed: () {
                    // TODO: Implement edit lesson content
                    ToastUtils.showInfo('Tính năng chỉnh sửa nội dung đang phát triển');
                  },
                  tooltip: 'Chỉnh sửa nội dung bài học',
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (documentUrl != null && documentUrl.isNotEmpty) ...[
            const Text('Tài liệu học tập:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openLessonDocument(documentUrl, lessonTitle),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        documentUrl.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.file_present, 
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tài liệu bài học', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('Nhấn để xem tài liệu chi tiết', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade300),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (exercise != null && exercise.isNotEmpty) ...[
            const Text('Bài tập / Yêu cầu:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(exercise, style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 24),
          ],

          const Text('Nội dung lý thuyết:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(theory ?? 'Vui lòng theo dõi video và tài liệu đính kèm để nắm rõ kiến thức bài học.', 
            style: TextStyle(color: theory != null ? Colors.black87 : Colors.grey, height: 1.5)),
          
          const SizedBox(height: 32),
          if (_selectedLesson!['linkVideo'] == null || _selectedLesson!['linkVideo'].isEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCompleted ? null : () => _completeLesson(_selectedLesson!['maBaiHoc']),
                icon: Icon(isCompleted ? Icons.check_circle : Icons.check_circle_outline),
                label: Text(isCompleted ? 'Đã hoàn thành' : 'Đánh dấu hoàn thành'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            )
          else if (!isCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bài học sẽ tự động hoàn thành khi bạn xem hết video.',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          if (isCompleted && _progress >= 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openCertificate(),
                  icon: const Icon(Icons.workspace_premium, color: Colors.orange),
                  label: const Text('Nhận chứng chỉ', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openLessonDocument(String? url, String title) {
    if (url == null || url.isEmpty) {
      ToastUtils.showInfo('Bài học này chưa có tài liệu đính kèm');
      return;
    }
    _openDocument(url, title);
  }

  void _openCertificate() {
    final String? certUrl = _learningData?['linkChungChi'];
    
    // Nếu đạt 100% hoặc có link chứng chỉ, hiển thị Preview giống bên Frontend
    if (_progress >= 1.0 || (certUrl != null && certUrl.isNotEmpty)) {
      _showCertificatePreview(certUrl);
    } else {
      ToastUtils.showInfo('Hãy hoàn thành 100% bài học để nhận chứng chỉ!');
    }
  }

  void _showCertificatePreview(String? certUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 28),
                    SizedBox(width: 12),
                    Text('Chúc mừng hoàn thành!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              // Certificate Body (Preview)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Column(
                    children: [
                      const Text('CHỨNG CHỈ HOÀN THÀNH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF0F172A))),
                      const SizedBox(height: 8),
                      const Text('GIẤY CHỨNG NHẬN ĐƯỢC TRAO CHO', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), letterSpacing: 1)),
                      const SizedBox(height: 16),
                      Text(_userName, style: GoogleFonts.dancingScript(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8))),
                      const Divider(indent: 40, endIndent: 40, color: Color(0xFFCBD5E1), thickness: 1.5),
                      const SizedBox(height: 12),
                      const Text('Đã xuất sắc hoàn thành khóa học:', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      Text(_learningData?['tieuDe'] ?? 'Khóa học', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ngày cấp: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                              const Text('ID: CERT-82391', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                            ],
                          ),
                          const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 32),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Đây là bản xem trước. Bạn có thể nhấn nút bên dưới để tải về hoặc xem bản PDF chính thức.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (certUrl != null && certUrl.isNotEmpty) {
                            _openDocument(certUrl, 'Chứng chỉ hoàn thành');
                          } else {
                            // Fallback nếu server chưa có link thật thì dùng link dummy
                            _openDocument("https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf", 'Chứng chỉ hoàn thành');
                          }
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Xem/Tải PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurriculum() {
    final List chapters = _learningData!['chuongs'] ?? [];
    return ListView.builder(
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final List lessons = chapter['baiHocs'] ?? [];
        final List quizzes = chapter['baiKiemTras'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              width: double.infinity,
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  Expanded(
                    child: Text('Chương ${index + 1}: ${chapter['tieuDe']}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  // Admin Action: Delete Chapter
                  if (_userRole == 'Admin')
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement delete chapter
                        ToastUtils.showInfo('Tính năng xóa chương đang phát triển');
                      },
                      child: const Icon(Icons.delete_sweep, size: 18, color: Colors.redAccent),
                    ),
                ],
              ),
            ),
            ...lessons.map((lesson) {
              final isSelected = _selectedLesson?['maBaiHoc'] == lesson['maBaiHoc'];
              final isCompleted = lesson['daHoanThanh'] ?? false;
              final isLocked = _isLessonLocked(lesson);
              
              return ListTile(
                dense: true,
                enabled: !isLocked,
                selected: isSelected,
                selectedTileColor: Colors.blue.shade50.withOpacity(0.5),
                leading: Icon(
                  isLocked ? Icons.lock_outline : (isCompleted ? Icons.check_circle : Icons.play_arrow),
                  color: isLocked ? Colors.grey.shade400 : (isCompleted ? Colors.green : (isSelected ? Colors.blue : Colors.grey)),
                  size: 18,
                ),
                title: Text(
                  lesson['tieuDe'] ?? 'Bài học', 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isLocked ? Colors.grey : (isSelected ? Colors.blue : Colors.black87)
                  )
                ),
                onTap: isLocked ? null : () => _onLessonSelected(lesson),
              );
            }).toList(),
            ...quizzes.map((quiz) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.assignment, color: Colors.orange, size: 18),
                title: Text(
                  quiz['tieuDe'] ?? 'Bài kiểm tra',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                onTap: () async {
                  final passed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(quizId: quiz['maBaiKiemTra']),
                    ),
                  );
                  if (passed == true) {
                    _loadContent(); // Refresh progress if passed
                  }
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
