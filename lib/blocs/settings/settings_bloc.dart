import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_service.dart';

import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<TogglePushNotificationEvent>(_onTogglePush);
    on<ToggleEmailNotificationEvent>(_onToggleEmail);
    on<ToggleDarkModeEvent>(_onToggleDarkMode);
    on<ChangeLanguageEvent>(_onChangeLanguage);
    on<DeactivateAccountEvent>(_onDeactivateAccount);
  }

  Future<void> _onLoadSettings(LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final push = prefs.getBool('pushNotifications') ?? true;
      final email = prefs.getBool('emailNotifications') ?? false;
      final dark = prefs.getBool('darkMode') ?? false;
      final lang = prefs.getString('language') ?? 'vi';

      emit(SettingsLoaded(
        pushNotifications: push,
        emailNotifications: email,
        darkMode: dark,
        language: lang,
      ));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> _onTogglePush(TogglePushNotificationEvent event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pushNotifications', event.value);
      
      emit(SettingsLoaded(
        pushNotifications: event.value,
        emailNotifications: currentState.emailNotifications,
        darkMode: currentState.darkMode,
        language: currentState.language,
      ));
    }
  }

  Future<void> _onToggleEmail(ToggleEmailNotificationEvent event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('emailNotifications', event.value);
      
      emit(SettingsLoaded(
        pushNotifications: currentState.pushNotifications,
        emailNotifications: event.value,
        darkMode: currentState.darkMode,
        language: currentState.language,
      ));
    }
  }

  Future<void> _onToggleDarkMode(ToggleDarkModeEvent event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', event.value);
      
      emit(SettingsLoaded(
        pushNotifications: currentState.pushNotifications,
        emailNotifications: currentState.emailNotifications,
        darkMode: event.value,
        language: currentState.language,
      ));
    }
  }

  Future<void> _onChangeLanguage(ChangeLanguageEvent event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', event.language);
      
      emit(SettingsLoaded(
        pushNotifications: currentState.pushNotifications,
        emailNotifications: currentState.emailNotifications,
        darkMode: currentState.darkMode,
        language: event.language,
      ));
    }
  }

  Future<void> _onDeactivateAccount(DeactivateAccountEvent event, Emitter<SettingsState> emit) async {
    emit(AccountDeactivating());
    try {
      await UserService.deactivateAccount();
      emit(AccountDeactivated());
    } catch (e) {
      emit(AccountDeactivationError(e.toString()));
      // Phục hồi lại state sau khi có lỗi
      add(LoadSettingsEvent());
    }
  }
}
