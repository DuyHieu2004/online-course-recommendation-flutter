import '../../models/user_profile_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile user;
  ProfileLoaded(this.user);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileAvatarUploading extends ProfileState {}

class ProfileAvatarUploadSuccess extends ProfileState {
  final String newAvatarUrl;
  ProfileAvatarUploadSuccess(this.newAvatarUrl);
}

class ProfileAvatarUploadFailure extends ProfileState {
  final String errorMessage;
  ProfileAvatarUploadFailure(this.errorMessage);
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {
  final UserProfile user;
  ProfileUpdateSuccess(this.user);
}

class ProfileUpdateFailure extends ProfileState {
  final String errorMessage;
  ProfileUpdateFailure(this.errorMessage);
}