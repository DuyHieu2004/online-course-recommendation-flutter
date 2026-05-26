import 'package:flutter/material.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  final int quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic>? _quizData;
  bool _isLoading = true;
  final Map<int, int> _selectedAnswers = {}; // maCauHoi -> maLuaChon
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final data = await QuizService.getQuizDetails(widget.quizId);
    if (mounted) {
      setState(() {
        _quizData = data;
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (_quizData == null) return;
    List cauHois = _quizData!['cauHois'] ?? [];
    if (_selectedAnswers.length < cauHois.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời tất cả các câu hỏi.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    final List<Map<String, int>> answers = _selectedAnswers.entries
        .map((e) => {'maCauHoi': e.key, 'maLuaChon': e.value})
        .toList();

    final result = await QuizService.submitQuiz(widget.quizId, answers);
    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final double score = (result['totalScore'] ?? 0).toDouble();
          final double maxScore = (result['maxScore'] ?? 0).toDouble();
          final bool passed = result['percentage'] >= 50;

          return AlertDialog(
            title: Text(passed ? 'Chúc mừng!' : 'Chưa đạt!'),
            content: Text('Bạn đạt được $score / $maxScore điểm.\n${passed ? "Bạn đã vượt qua bài kiểm tra." : "Vui lòng học lại và làm bài lại."}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, passed); // go back
                },
                child: const Text('Đóng'),
              )
            ],
          );
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi nộp bài.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_quizData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không thể tải bài kiểm tra')),
      );
    }

    List cauHois = _quizData!['cauHois'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_quizData!['tieuDe'] ?? 'Bài Kiểm Tra'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blue.shade50,
            child: Text(
              _quizData!['moTa'] ?? 'Hãy chọn đáp án đúng cho các câu hỏi sau.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cauHois.length,
              itemBuilder: (context, index) {
                final cauHoi = cauHois[index];
                final List luaChons = cauHoi['luaChons'] ?? [];
                final maCauHoi = cauHoi['maCauHoi'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Câu ${index + 1}: ${cauHoi['noiDung']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...luaChons.map((lc) {
                          return RadioListTile<int>(
                            title: Text(lc['noiDung']),
                            value: lc['maLuaChon'],
                            groupValue: _selectedAnswers[maCauHoi],
                            onChanged: (val) {
                              setState(() {
                                _selectedAnswers[maCauHoi] = val!;
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Nộp bài', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
