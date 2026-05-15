import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_profile_model.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'transaction_history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await AuthService.clearAuthData();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), 
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: const Color(0xFFFFCC33),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _user == null 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC33)))
        : SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildMenuSection(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC33), width: 3),
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _user!.email,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuItem(Icons.person_outline, 'Chỉnh sửa hồ sơ', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildDivider(),
            _buildMenuItem(Icons.lock_outline, 'Đổi mật khẩu', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            }),
            _buildDivider(),
            _buildMenuItem(Icons.history_rounded, 'Lịch sử giao dịch', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
            }),
            _buildDivider(),
            _buildMenuItem(Icons.settings_outlined, 'Cài đặt hệ thống', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
            _buildDivider(),
            _buildMenuItem(Icons.help_outline, 'Trợ giúp & Hỗ trợ', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            }),
            _buildDivider(),
            _buildMenuItem(
              Icons.logout_rounded, 
              'Đăng xuất', 
              color: Colors.red, 
              hideArrow: true,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = Colors.black87, bool hideArrow = false, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color == Colors.red ? Colors.red.shade50 : Colors.grey.shade100, 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              if (!hideArrow)
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 20),
      child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
    );
  }
}