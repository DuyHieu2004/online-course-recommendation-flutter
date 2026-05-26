import 'package:flutter/material.dart';
import '../utils/toast_utils.dart';
import 'home_screen.dart';
import 'course_list_screen.dart';
import 'bookmarks_screen.dart';
import 'profile_screen.dart';
import 'ai_recommendations_screen.dart'; // <-- IMPORT FILE MỚI VÀO ĐÂY

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // THÊM HÀM KHỞI TẠO ĐỘNG NÀY
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const CourseListScreen();
      case 2:
        return const BookmarksScreen(); // Tự động gọi lại initState() để tải giỏ hàng mới
      case 3:
        return const ProfileScreen(); // Tự động reload tiến độ học tập mới
      default:
        return const HomeScreen();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SỬA DÒNG NÀY: Gọi hàm _buildBody() thay vì mảng _screens[_selectedIndex]
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFAB() {
    return Transform.translate(
      offset: const Offset(0, 5),
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // CHUYỂN HƯỚNG SANG TRANG GỢI Ý AI
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiRecommendationsScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEDE7F6),
                    Color(0xFFF3E5F5),
                  ], // Tone màu tím AI
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // ĐỔI ICON THÀNH CÂY ĐŨA PHÉP (auto_fix_high là icon chuẩn nhất trong Material)
              child: const Icon(
                Icons.auto_fix_high,
                color: Color(0xFF8E24AA),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.school_outlined, 'Courses', 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.bookmark_border, 'Giỏ hàng', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF1E88E5) : Colors.black54,
                  size: 26,
                ),
                const SizedBox(height: 4),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E88E5),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
