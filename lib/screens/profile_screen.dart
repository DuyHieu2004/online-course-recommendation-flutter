import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khoa_hoc_online/blocs/profile/profile_bloc.dart';
import 'package:khoa_hoc_online/blocs/profile/profile_event.dart';

import '../services/auth_service.dart';
import '../models/user_profile_model.dart';
import '../blocs/profile/profile_state.dart'; // Import Bloc vừa tạo

import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'transaction_history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp Bloc cho toàn màn hình
    return BlocProvider(
      create: (context) => ProfileBloc()..add(LoadProfileEvent()),
      child: const ProfileScreenView(),
    );
  }
}

class ProfileScreenView extends StatefulWidget {
  const ProfileScreenView({super.key});

  @override
  State<ProfileScreenView> createState() => _ProfileScreenViewState();
}

class _ProfileScreenViewState extends State<ProfileScreenView> {
  UserProfile? _user;
  File? _selectedLocalImage; // Lưu ảnh vừa chọn từ điện thoại
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Khởi tạo không cần gọi API thủ công nữa vì Bloc đã xử lý
  }

  // Hàm gọi thư viện chọn ảnh
  Future<void> _pickImage(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
      );

      if (pickedFile != null) {
        setState(() {
          _selectedLocalImage = File(pickedFile.path);
        });
        
        // Bắn Event cho Bloc xử lý upload
        if (mounted) {
          context.read<ProfileBloc>().add(UploadAvatarEvent(_selectedLocalImage!));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi mở thư viện ảnh')),
      );
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
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileAvatarUploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
            );
            _selectedLocalImage = null;
          } else if (state is ProfileAvatarUploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          } else if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
            );
          } else if (state is ProfileError) {
            // Xử lý tự động đăng xuất nếu token hết hạn
            if (state.message.contains('hết hạn')) {
              AuthService.clearAuthData();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.')),
              );
            }
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC33)));
            }
            
            // Xử lý lấy thông tin user từ state
            if (state is ProfileLoaded) {
              _user = state.user;
            } else if (state is ProfileUpdateSuccess) {
              _user = state.user;
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (state is ProfileError)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Text('Lỗi: ${state.message}', style: const TextStyle(color: Colors.red)),
                    )
                  else if (_user != null)
                    _buildProfileHeader(context),
                  
                  const SizedBox(height: 24),
                  _buildMenuSection(context),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Dùng BlocBuilder bao quanh khu vực Avatar để build lại UI khi loading
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              bool isUploading = state is ProfileAvatarUploading;

              return Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFCC33), width: 3),
                    ),
                    // Logic ưu tiên hiển thị: Ảnh mới chọn -> Ảnh từ API -> Icon mặc định
                    child: ClipOval(
                      child: _selectedLocalImage != null
                          ? Image.file(_selectedLocalImage!, fit: BoxFit.cover)
                          : (_user!.linkAnhDaiDien != null && _user!.linkAnhDaiDien!.isNotEmpty)
                              ? Image.network(
                                  _user!.linkAnhDaiDien!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.person, size: 60, color: Colors.grey),
                                )
                              : const Icon(Icons.person, size: 60, color: Colors.grey),
                    ),
                  ),
                  if (isUploading)
                    const Positioned.fill(
                      child: CircularProgressIndicator(color: Color(0xFFFFCC33)),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: isUploading ? null : () => _pickImage(context),
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
                  ),
                ],
              );
            },
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

  // _buildMenuSection, _buildMenuItem, _buildDivider giữ nguyên như cũ...
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<ProfileBloc>(),
                    child: const EditProfileScreen(),
                  ),
                ),
              );
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