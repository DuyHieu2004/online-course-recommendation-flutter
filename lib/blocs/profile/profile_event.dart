import 'dart:io';

abstract class ProfileEvent {}

class LoadProfileEvent extends ProfileEvent {}

class UploadAvatarEvent extends ProfileEvent {
  final File imageFile;
  UploadAvatarEvent(this.imageFile);
}

class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? bio;

  UpdateProfileEvent({this.name, this.bio});
}