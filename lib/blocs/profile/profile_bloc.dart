import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile_model.dart';

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  UserProfile? _currentUser;

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UploadAvatarEvent>(_onUploadAvatar);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        emit(ProfileError('Không thể lấy thông tin người dùng cục bộ.'));
        return;
      }
      
      final profileData = await UserService.getProfile();
      user.name = profileData['ten'] ?? user.name;
      user.linkAnhDaiDien = profileData['linkAnhDaiDien'];
      user.tieuSu = profileData['tieuSu'];
      
      _currentUser = user;
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUploadAvatar(UploadAvatarEvent event, Emitter<ProfileState> emit) async {
    // Lưu lại state hiện tại nếu đang ở ProfileLoaded
    final previousState = state;
    
    emit(ProfileAvatarUploading());
    try {
      final imageUrl = await UserService.uploadAvatar(event.imageFile);
      await UserService.updateProfile(linkAnhDaiDien: imageUrl);
      
      if (_currentUser != null) {
        _currentUser!.linkAnhDaiDien = imageUrl;
      }
      
      emit(ProfileAvatarUploadSuccess(imageUrl));
      if (_currentUser != null) {
        emit(ProfileLoaded(_currentUser!)); // Trở về trạng thái Loaded
      }
    } catch (e) {
      emit(ProfileAvatarUploadFailure(e.toString()));
      if (previousState is ProfileLoaded) {
        emit(previousState);
      }
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    final previousState = state;
    emit(ProfileUpdating());
    try {
      await UserService.updateProfile(ten: event.name, tieuSu: event.bio);
      
      if (_currentUser != null) {
        if (event.name != null) _currentUser!.name = event.name!;
        if (event.bio != null) _currentUser!.tieuSu = event.bio!;
      }
      
      emit(ProfileUpdateSuccess(_currentUser!));
      emit(ProfileLoaded(_currentUser!));
    } catch (e) {
      emit(ProfileUpdateFailure(e.toString()));
      if (previousState is ProfileLoaded) {
        emit(previousState);
      }
    }
  }
}