import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  void _showDeactivateConfirmDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == 'vi' ? 'Xóa tài khoản' : 'Deactivate Account', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(lang == 'vi' 
            ? 'Bạn có chắc chắn muốn xóa (vô hiệu hóa) tài khoản này không? Thao tác này không thể hoàn tác.' 
            : 'Are you sure you want to deactivate this account? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang == 'vi' ? 'Hủy' : 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SettingsBloc>().add(DeactivateAccountEvent());
            },
            child: Text(lang == 'vi' ? 'Xóa' : 'Deactivate', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, String currentLang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentLang == 'vi' ? 'Chọn Ngôn ngữ' : 'Select Language', style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tiếng Việt'),
              trailing: currentLang == 'vi' ? const Icon(Icons.check, color: Color(0xFFFFCC33)) : null,
              onTap: () {
                context.read<SettingsBloc>().add(ChangeLanguageEvent('vi'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: currentLang == 'en' ? const Icon(Icons.check, color: Color(0xFFFFCC33)) : null,
              onTap: () {
                context.read<SettingsBloc>().add(ChangeLanguageEvent('en'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is AccountDeactivated) {
          AuthService.clearAuthData();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else if (state is AccountDeactivationError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          bool push = true;
          bool email = false;
          bool dark = false;
          String lang = 'vi';

          if (state is SettingsLoaded) {
            push = state.pushNotifications;
            email = state.emailNotifications;
            dark = state.darkMode;
            lang = state.language;
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? Colors.black : const Color(0xFFF4F6F8);
          final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black87;

          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              title: Text(lang == 'vi' ? 'Cài đặt' : 'Settings', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
              backgroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: textColor),
            ),
            body: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    _buildSectionHeader(lang == 'vi' ? 'Tùy chỉnh thông báo' : 'Notification Settings'),
                    _buildSettingsCard(
                      cardColor: cardColor,
                      children: [
                        _buildSwitchTile(
                          lang == 'vi' ? 'Thông báo đẩy (Push)' : 'Push Notifications', 
                          lang == 'vi' ? 'Nhận thông báo khóa học mới trên máy' : 'Receive course updates on device', 
                          push, (val) => context.read<SettingsBloc>().add(TogglePushNotificationEvent(val)),
                          isDark
                        ),
                        Divider(height: 1, indent: 16, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        _buildSwitchTile(
                          lang == 'vi' ? 'Thông báo Email' : 'Email Notifications', 
                          lang == 'vi' ? 'Nhận email khuyến mãi & bài tập' : 'Receive promo & assignment emails', 
                          email, (val) => context.read<SettingsBloc>().add(ToggleEmailNotificationEvent(val)),
                          isDark
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(lang == 'vi' ? 'Giao diện & Hệ thống' : 'System & Appearance'),
                    _buildSettingsCard(
                      cardColor: cardColor,
                      children: [
                        _buildSwitchTile(
                          lang == 'vi' ? 'Chế độ tối (Dark Mode)' : 'Dark Mode', 
                          lang == 'vi' ? 'Giảm mỏi mắt khi học ban đêm' : 'Reduce eye strain at night', 
                          dark, (val) => context.read<SettingsBloc>().add(ToggleDarkModeEvent(val)),
                          isDark
                        ),
                        Divider(height: 1, indent: 16, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        ListTile(
                          title: Text(lang == 'vi' ? 'Ngôn ngữ' : 'Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
                          trailing: Text(lang == 'vi' ? 'Tiếng Việt' : 'English', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          onTap: () => _showLanguageDialog(context, lang),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader(lang == 'vi' ? 'Khác' : 'Other'),
                    _buildSettingsCard(
                      cardColor: cardColor,
                      children: [
                        ListTile(
                          title: Text(lang == 'vi' ? 'Xóa tài khoản' : 'Deactivate Account', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.red)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                          onTap: () => _showDeactivateConfirmDialog(context, lang),
                        ),
                      ],
                    ),
                  ],
                ),
                if (state is AccountDeactivating)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFCC33))),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      // Gọi .toUpperCase() thẳng vào biến title luôn
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey.shade600
        )
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, required Color cardColor}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, bool isDark) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      value: value,
      activeColor: const Color(0xFFFFCC33),
      onChanged: onChanged,
    );
  }
}