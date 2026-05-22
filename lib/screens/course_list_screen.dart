import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import 'package:intl/intl.dart';
import '../models/course_model.dart';
import '../models/user_profile_model.dart';
import 'course_details_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  List<EnrolledCourse> _enrolledCourses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courses = await CourseService.getMyCourses();
    if (mounted) {
      setState(() {
        _enrolledCourses = courses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Courses', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFFFFCC33),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrolledCourses.isEmpty
              ? const Center(child: Text('You are not enrolled in any courses yet.', style: TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: _loadCourses,
                  child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                  itemCount: _enrolledCourses.length,
                  itemBuilder: (context, index) {
                    final course = _enrolledCourses[index];
                    return InkWell(
                      onTap: () {
                        if (course.isExpired) {
                          // Show repurchase dialog or go to details to buy
                          _showRepurchaseDialog(course);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourseDetailsScreen(courseId: course.id)),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: course.isExpired ? Colors.red.shade100 : Colors.grey.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: course.isExpired ? Colors.red.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  image: course.imageUrl != null 
                                      ? DecorationImage(image: NetworkImage(course.imageUrl!), fit: BoxFit.cover, colorFilter: course.isExpired ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : null) 
                                      : null,
                                ),
                                child: course.imageUrl == null ? Icon(Icons.school, color: course.isExpired ? Colors.red : const Color(0xFF1E88E5), size: 36) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(course.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: course.isExpired ? Colors.grey : Colors.black)),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: course.progress,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(course.isExpired ? Colors.grey : (course.isCompleted ? const Color(0xFF10B981) : const Color(0xFF1E88E5))),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${(course.progress * 100).toInt()}% Completed', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                        Text(course.progress >= 1.0 ? 'Hoàn thành' : course.status, style: const TextStyle(color: Color(0xFF1E88E5), fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (course.isExpired)
                                      ElevatedButton(
                                        onPressed: () => _showRepurchaseDialog(course),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(double.infinity, 30),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Mua lại để tiếp tục học', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Hết hạn: ${course.expiryDate != null ? DateFormat('dd/MM/yyyy').format(course.expiryDate!) : "Vĩnh viễn"}',
                                                style: TextStyle(
                                                  color: Colors.orange.shade900,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
    );
  }

  void _showRepurchaseDialog(EnrolledCourse course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khoá học đã hết hạn', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Khoá học "${course.title}" đã hết hạn. Bạn cần mua lại để tiếp tục học. Toàn bộ tiến độ học tập cũ sẽ được giữ nguyên.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailsScreen(courseId: course.id)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
            child: const Text('Mua lại ngay'),
          ),
        ],
      ),
    );
  }
}
