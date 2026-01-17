import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wish_listy/core/utils/image_utils.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/profile/data/repository/profile_repository.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_state.dart';

/// Profile Cubit for managing profile image upload and deletion
class ProfileCubit extends Cubit<ProfileImageState> {
  final ProfileRepository _repository;
  final ImagePicker _imagePicker;
  String? _currentProfileImageUrl; // Track current profile image to decide upload vs edit

  ProfileCubit({ProfileRepository? repository, String? currentProfileImageUrl})
      : _repository = repository ?? ProfileRepository(),
        _imagePicker = ImagePicker(),
        _currentProfileImageUrl = currentProfileImageUrl,
        super(ProfileImageInitial());
  
  // Update current profile image URL
  void setCurrentProfileImage(String? imageUrl) {
    _currentProfileImageUrl = imageUrl;
  }

  /// Pick image from specified source and upload
  /// This is a unified method that can be used for both camera and gallery
  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      await pickImageFromCamera();
    } else if (source == ImageSource.gallery) {
      await pickImageFromGallery();
    }
  }

  /// Pick image from camera and upload
  Future<void> pickImageFromCamera() async {
    try {
      // Pick image from camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100, // We'll compress it ourselves
      );

      if (image == null) {
        // User cancelled
        return;
      }

      // Check if user has existing profile image
      final hasExistingImage = _currentProfileImageUrl != null && 
                               _currentProfileImageUrl!.isNotEmpty &&
                               !_currentProfileImageUrl!.contains('placeholder') &&
                               !_currentProfileImageUrl!.contains('default');
      
      await _uploadImage(image.path, hasExistingImage: hasExistingImage);
    } on PlatformException catch (e) {
      // Handle permission denied
      if (e.code == 'camera_access_denied' || 
          e.code == 'camera_access_denied_permanently' ||
          e.message?.contains('permission') == true ||
          e.message?.contains('access') == true) {
        emit(ProfileImageUploadError(
          'Camera permission is required to take photos. Please grant permission in settings.',
        ));
      } else {
        emit(ProfileImageUploadError(
          'Failed to pick image from camera: ${e.message ?? e.toString()}',
        ));
      }
    } catch (e) {
      // Check for permission-related errors
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') || 
          errorMessage.contains('access denied') ||
          errorMessage.contains('not granted')) {
        emit(ProfileImageUploadError(
          'Camera permission is required to take photos. Please grant permission in settings.',
        ));
      } else {
        emit(ProfileImageUploadError(
          'Failed to pick image from camera: ${e.toString()}',
        ));
      }
    }
  }

  /// Pick image from gallery and upload
  Future<void> pickImageFromGallery() async {
    try {
      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // We'll compress it ourselves
      );

      if (image == null) {
        // User cancelled
        return;
      }

      // Check if user has existing profile image
      final hasExistingImage = _currentProfileImageUrl != null && 
                               _currentProfileImageUrl!.isNotEmpty &&
                               !_currentProfileImageUrl!.contains('placeholder') &&
                               !_currentProfileImageUrl!.contains('default');
      
      await _uploadImage(image.path, hasExistingImage: hasExistingImage);
    } on PlatformException catch (e) {
      // Handle permission denied
      if (e.code == 'photo_access_denied' || 
          e.code == 'photo_access_denied_permanently' ||
          e.message?.contains('permission') == true ||
          e.message?.contains('access') == true) {
        emit(ProfileImageUploadError(
          'Gallery permission is required to select photos. Please grant permission in settings.',
        ));
      } else {
        emit(ProfileImageUploadError(
          'Failed to pick image from gallery: ${e.message ?? e.toString()}',
        ));
      }
    } catch (e) {
      // Check for permission-related errors
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('permission') || 
          errorMessage.contains('access denied') ||
          errorMessage.contains('not granted')) {
        emit(ProfileImageUploadError(
          'Gallery permission is required to select photos. Please grant permission in settings.',
        ));
      } else {
        emit(ProfileImageUploadError(
          'Failed to pick image from gallery: ${e.toString()}',
        ));
      }
    }
  }

  /// Internal method to compress and upload/edit image
  /// [imagePath] - Path to the image file
  /// [hasExistingImage] - Whether user already has a profile image (use edit API if true)
  Future<void> _uploadImage(String imagePath, {bool hasExistingImage = false}) async {
    try {
      emit(ProfileImageUploading());

      // Compress image to target size (~500KB, max 800x800)
      final compressedPath = await ImageUtils.compressImage(imagePath);

      // Use edit API if user has existing image, otherwise use upload API
      final response = hasExistingImage
          ? await _repository.editProfileImage(compressedPath)
          : await _repository.uploadProfileImage(compressedPath);

      // Extract imageUrl and user data from response
      final data = response['data'] ?? response;
      final imageUrl = data['imageUrl'] as String?;
      final userData = data['user'] as Map<String, dynamic>? ?? data;

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('No image URL returned from server');
      }

      // Update current profile image URL
      _currentProfileImageUrl = imageUrl;
      
      emit(ProfileImageUploadSuccess(
        imageUrl: imageUrl,
        userData: userData,
      ));
    } on ApiException catch (e) {
      emit(ProfileImageUploadError(e.message));
    } catch (e) {
      emit(ProfileImageUploadError(
        'Failed to upload image: ${e.toString()}',
      ));
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      emit(ProfileImageDeleting());

      final response = await _repository.deleteProfileImage();

      // Extract updated user data from response (profileImage should be null)
      final data = response['data'] ?? response;
      final userData = data['user'] as Map<String, dynamic>? ?? data;

      // Update current profile image URL to null
      _currentProfileImageUrl = null;
      
      emit(ProfileImageDeleteSuccess(userData: userData));
    } on ApiException catch (e) {
      emit(ProfileImageDeleteError(e.message));
    } catch (e) {
      emit(ProfileImageDeleteError(
        'Failed to delete image: ${e.toString()}',
      ));
    }
  }
}

