import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/settings/settings_bloc.dart';
import 'blocs/settings/settings_event.dart';
import 'blocs/settings/settings_state.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc()..add(LoadSettingsEvent()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          bool isDark = false;
          if (state is SettingsLoaded) {
            isDark = state.darkMode;
          }
          
          return MaterialApp(
            title: 'Khoa Hoc Online',
            debugShowCheckedModeBanner: false,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFCC33)),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFFCC33),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF121212),
            ),
            home: isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
