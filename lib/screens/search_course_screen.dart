import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import '../models/user_profile_model.dart';
import 'course_details_screen.dart';

class SearchCourseScreen extends StatefulWidget {
  const SearchCourseScreen({super.key});

  @override
  State<SearchCourseScreen> createState() => _SearchCourseScreenState();
}

class _SearchCourseScreenState extends State<SearchCourseScreen> {
  final _searchController = TextEditingController();
  List<ApiCourse> _courses = [];
  bool _isLoading = false;

  void _search() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final results = await CourseService.searchCourses(query);
    setState(() {
      _courses = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search courses...',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              final course = _courses[index];
              return _buildCourseCard(course);
            },
          ),
    );
  }

  Widget _buildCourseCard(ApiCourse course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseDetailsScreen(courseId: course.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  image: course.imageUrl != null 
                    ? DecorationImage(image: NetworkImage(course.imageUrl!), fit: BoxFit.cover)
                    : null,
                ),
                child: course.imageUrl == null ? const Icon(Icons.image, color: Colors.grey) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.instructorName ?? 'Unknown Instructor',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${course.price.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(course.rating.toStringAsFixed(1)),
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
}
