import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wish_listy/core/services/api_service.dart' show ApiException;
import 'package:wish_listy/features/profile/data/repository/profile_repository.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_state.dart';

/// Profile Cubit for managing profile image upload and deletion.
/// Uses privacy-first approach: ImageSource.gallery triggers Android Photo Picker on Android 13+
/// without requiring READ_MEDIA_IMAGES or CAMERA permissions.
class ProfileCubit extends Cubit<ProfileImageState> {
  final ProfileRepository _repository;
  final ImagePicker _imagePicker;
  String? _currentProfileImageUrl;

  ProfileCubit({ProfileRepository? repository, String? currentProfileImageUrl})
      : _repository = repository ?? ProfileRepository(),
        _imagePicker = ImagePicker(),
        _currentProfileImageUrl = currentProfileImageUrl,
        super(ProfileImageInitial());

  void setCurrentProfileImage(String? imageUrl) {
    _currentProfileImageUrl = imageUrl;
  }

  /// Pick image from gallery and upload. Uses Android Photo Picker on Android 13+.
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final hasExistingImage = _currentProfileImageUrl != null &&
          _currentProfileImageUrl!.isNotEmpty &&
          !_currentProfileImageUrl!.contains('placeholder') &&
          !_currentProfileImageUrl!.contains('default');

      await _uploadImage(image.path, hasExistingImage: hasExistingImage);
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied' ||
          e.code == 'photo_access_denied_permanently' ||
          e.message?.contains('permission') == true ||
          e.message?.contains('access') == true) {
        emit(ProfileImageUploadError(
          'Gallery permission is required to select photos. Please grant permission in settings.',
        ));
      } else {
        emit(ProfileImageUploadError(
          'Failed to pick image: ${e.message ?? e.toString()}',
        ));
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') ||
          errorMessage.contains('access denied') ||
          errorMessage.contains('not granted')) {
        emit(ProfileImageUploadError(
          'Gallery permission is required to select photos. Please grant permission in settings.',
        ));
      } else {
        emit(ProfileImageUploadError('Failed to upload image: ${e.toString()}'));
      }
    }
  }

  Future<void> _uploadImage(String imagePath,
      {required bool hasExistingImage}) async {
    try {
      emit(ProfileImageUploading());

      final response = hasExistingImage
          ? await _repository.editProfileImage(imagePath)
          : await _repository.uploadProfileImage(imagePath);

      final imageUrl = response['imageUrl'] as String?;
      final userData = response['user'] as Map<String, dynamic>? ?? response;

      if (imageUrl == null || imageUrl.isEmpty) {
        emit(ProfileImageUploadError('No image URL returned from server'));
        return;
      }

      _currentProfileImageUrl = imageUrl;
      emit(ProfileImageUploadSuccess(
        imageUrl: imageUrl,
        userData: userData,
      ));
    } on ApiException catch (e) {
      emit(ProfileImageUploadError(e.message));
    } catch (e) {
      emit(ProfileImageUploadError('Failed to upload image: ${e.toString()}'));
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      emit(ProfileImageDeleting());

      final response = await _repository.deleteProfileImage();
      final data = response['data'] ?? response;
      final userData = data['user'] as Map<String, dynamic>? ?? data;

      _currentProfileImageUrl = null;
      emit(ProfileImageDeleteSuccess(userData: userData));
    } on ApiException catch (e) {
      emit(ProfileImageDeleteError(e.message));
    } catch (e) {
      emit(ProfileImageDeleteError('Failed to delete image: ${e.toString()}'));
    }
  }
}
