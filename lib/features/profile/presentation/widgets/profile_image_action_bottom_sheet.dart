import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

              // Title
              Text(
                localization.translate('profile.changeProfilePicture'),
                style: AppStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontFamily: 'Alexandria',
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 20),

              // Take Photo Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Get the cubit before closing the bottom sheet
                    final cubit = context.read<ProfileCubit>();
                    Navigator.pop(context);
                    // Call cubit method after bottom sheet closes
                    await Future.delayed(const Duration(milliseconds: 100));
                    await cubit.pickImage(ImageSource.camera);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          localization.translate('profile.takePhoto'),
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Choose from Gallery Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    // Get the cubit before closing the bottom sheet
                    final cubit = context.read<ProfileCubit>();
                    Navigator.pop(context);
                    // Call cubit method after bottom sheet closes
                    await Future.delayed(const Duration(milliseconds: 100));
                    await cubit.pickImage(ImageSource.gallery);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          localization.translate('profile.chooseFromGallery'),
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Remove Photo Button (only show if user has uploaded image)
              if (hasUploadedImage) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirmed = await AppUtils.showConfirmDialog(
                        context,
                        title: localization.translate('profile.removePhoto'),
                        message: localization.translate('profile.confirmRemovePhoto'),
                        confirmText: localization.translate('app.remove'),
                        cancelText: localization.translate('app.cancel'),
                        confirmColor: AppColors.error,
                      );

                      if (confirmed && context.mounted) {
                        Navigator.pop(context);
                        context.read<ProfileCubit>().deleteProfileImage();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 24,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            localization.translate('profile.removePhoto'),
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
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

