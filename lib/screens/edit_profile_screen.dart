import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';
import '../blocs/profile/profile_state.dart';
import '../utils/QuickAlertService.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedLocalImage;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      _nameController.text = state.user.name;
      _bioController.text = state.user.tieuSu ?? '';
    } else if (state is ProfileUpdateSuccess) {
      _nameController.text = state.user.name;
      _bioController.text = state.user.tieuSu ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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

  void _saveProfile() {
    context.read<ProfileBloc>().add(
      UpdateProfileEvent(
        name: _nameController.text,
        bio: _bioController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          QuickAlertService.showAlertSuccess(context, 'Cập nhật hồ sơ thành công!');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        } else if (state is ProfileUpdateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage)));
        } else if (state is ProfileAvatarUploadSuccess) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            String? avatarUrl;
            if (state is ProfileLoaded) {
               avatarUrl = state.user.linkAnhDaiDien;
            } else if (state is ProfileUpdateSuccess) {
               avatarUrl = state.user.linkAnhDaiDien;
            }

            bool isUpdating = state is ProfileUpdating || state is ProfileAvatarUploading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // --- Avatar ---
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                          child: ClipOval(
                            child: _selectedLocalImage != null
                                ? Image.file(_selectedLocalImage!, fit: BoxFit.cover)
                                : (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => const Icon(Icons.person, size: 50, color: Colors.grey),
                                      )
                                    : const Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                        ),
                        if (state is ProfileAvatarUploading)
                          const Positioned.fill(
                            child: CircularProgressIndicator(color: Color(0xFFFFCC33)),
                          ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: state is ProfileAvatarUploading ? null : () => _pickImage(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFFFFCC33), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt, color: Colors.black87, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // --- Form Fields ---
                  _buildFlatTextField(label: 'Họ và Tên', controller: _nameController, icon: Icons.person_outline),
                  const SizedBox(height: 20),
                  //_buildFlatTextField(label: 'Số điện thoại', controller: _phoneController, icon: Icons.phone_outlined, isPhone: true),
                  //const SizedBox(height: 20),
                  _buildFlatTextField(label: 'Giới thiệu bản thân', controller: _bioController, icon: Icons.info_outline, maxLines: 3),
                  
                  const SizedBox(height: 40),
                  
                  // --- Save Button ---
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: isUpdating ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC33),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isUpdating 
                        ? const CircularProgressIndicator(color: Colors.black87)
                        : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFlatTextField({required String label, required TextEditingController controller, required IconData icon, int maxLines = 1, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFCC33), width: 2)),
          ),
        ),
      ],
    );
  }
}