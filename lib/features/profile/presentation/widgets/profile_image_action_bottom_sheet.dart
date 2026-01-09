import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_utils.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_cubit.dart';

/// Bottom sheet widget for profile image actions
class ProfileImageActionBottomSheet extends StatelessWidget {
  final String? currentImageUrl;
  final bool hasUploadedImage;

  const ProfileImageActionBottomSheet({
    super.key,
    this.currentImageUrl,
    required this.hasUploadedImage,
  });

  /// Show the bottom sheet
  static Future<void> show(
    BuildContext context, {
    String? currentImageUrl,
    required bool hasUploadedImage,
  }) {
    // Get the ProfileCubit from the parent context before opening bottom sheet
    final profileCubit = context.read<ProfileCubit>();
    
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => BlocProvider<ProfileCubit>.value(
        value: profileCubit,
        child: ProfileImageActionBottomSheet(
          currentImageUrl: currentImageUrl,
          hasUploadedImage: hasUploadedImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 8),

              // Take Photo Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Get the cubit before closing the bottom sheet
                    final cubit = context.read<ProfileCubit>();
                    Navigator.pop(context);
                    // Call cubit method after bottom sheet closes
                    await Future.delayed(const Duration(milliseconds: 100));
                    await cubit.pickImage(ImageSource.camera);
                  },
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    size: 24,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Take Photo',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Choose from Gallery Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Get the cubit before closing the bottom sheet
                    final cubit = context.read<ProfileCubit>();
                    Navigator.pop(context);
                    // Call cubit method after bottom sheet closes
                    await Future.delayed(const Duration(milliseconds: 100));
                    await cubit.pickImage(ImageSource.gallery);
                  },
                  icon: Icon(
                    Icons.photo_library_outlined,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Choose from Gallery',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              // Remove Photo Button (only show if user has uploaded image)
              if (hasUploadedImage) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirmed = await AppUtils.showConfirmDialog(
                        context,
                        title: 'Remove Photo',
                        message: 'Are you sure you want to remove your profile photo?',
                        confirmText: 'Remove',
                        cancelText: 'Cancel',
                        confirmColor: AppColors.error,
                      );

                      if (confirmed && context.mounted) {
                        Navigator.pop(context);
                        context.read<ProfileCubit>().deleteProfileImage();
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 24,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Remove Photo',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

