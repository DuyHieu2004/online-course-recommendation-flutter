abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool darkMode;
  final String language;

  SettingsLoaded({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.darkMode,
    required this.language,
  });
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
}

class AccountDeactivating extends SettingsState {}

class AccountDeactivated extends SettingsState {}

class AccountDeactivationError extends SettingsState {
  final String message;
  AccountDeactivationError(this.message);
}
