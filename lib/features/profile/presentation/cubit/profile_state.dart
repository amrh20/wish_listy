import 'package:equatable/equatable.dart';

/// Profile image upload/delete state
abstract class ProfileImageState extends Equatable {
  const ProfileImageState();

  @override
  List<Object?> get props => [];
}

class ProfileImageInitial extends ProfileImageState {}

class ProfileImageUploading extends ProfileImageState {}

class ProfileImageUploadSuccess extends ProfileImageState {
  final String imageUrl;
  final Map<String, dynamic>? userData;

  const ProfileImageUploadSuccess({
    required this.imageUrl,
    this.userData,
  });

  @override
  List<Object?> get props => [imageUrl, userData];
}

class ProfileImageUploadError extends ProfileImageState {
  final String message;

  const ProfileImageUploadError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileImageDeleting extends ProfileImageState {}

class ProfileImageDeleteSuccess extends ProfileImageState {
  final Map<String, dynamic>? userData;

  const ProfileImageDeleteSuccess({this.userData});

  @override
  List<Object?> get props => [userData];
}

class ProfileImageDeleteError extends ProfileImageState {
  final String message;

  const ProfileImageDeleteError(this.message);

  @override
  List<Object?> get props => [message];
}
