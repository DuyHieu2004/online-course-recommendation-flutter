import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/QuickAlertService.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  
  // Trạng thái ẩn/hiện của 3 ô mật khẩu
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    // Validate cơ bản
    if (_oldPasswordController.text.isEmpty || 
        _newPasswordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      QuickAlertService.showAlertWarning(context, 'Vui lòng điền đầy đủ thông tin!');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      QuickAlertService.showAlertWarning(context, 'Mật khẩu mới không khớp!');
      return;
    }

    if (_oldPasswordController.text == _newPasswordController.text) {
      QuickAlertService.showAlertWarning(context, 'Mật khẩu mới phải khác mật khẩu cũ!');
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await AuthService.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        QuickAlertService.showAlertSuccess(context, 'Đổi mật khẩu thành công!');
        // Đợi 1 chút cho user đọc thông báo rồi pop về
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        QuickAlertService.showAlertFailure(context, 'Đổi mật khẩu thất bại. Sai mật khẩu cũ!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Đổi mật khẩu', 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 18)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tạo mật khẩu mới',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Mật khẩu mới của bạn phải có ít nhất 6 ký tự và khác với mật khẩu cũ.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              // Form nhập liệu
              _buildPasswordField(
                controller: _oldPasswordController,
                label: 'Mật khẩu cũ',
                hint: 'Nhập mật khẩu hiện tại',
                isObscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: 20),
              
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Mật khẩu mới',
                hint: 'Nhập mật khẩu mới',
                isObscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 20),
              
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                hint: 'Nhập lại mật khẩu mới',
                isObscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              
              const SizedBox(height: 40),
              
              // Nút bấm xác nhận
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC33), // Màu vàng chủ đạo
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3)
                      )
                    : const Text(
                        'Cập nhật mật khẩu', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm helper để build TextField cho gọn code, tái sử dụng 3 lần
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade100, // Nền xám nhạt phẳng
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none, // Bỏ viền mặc định
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFFCC33), width: 2), // Viền vàng khi focus
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.grey.shade500,
                size: 22,
              ),
              onPressed: onToggle,
              splashRadius: 20,
            ),
          ),
        ),
      ],
    );
  }
}