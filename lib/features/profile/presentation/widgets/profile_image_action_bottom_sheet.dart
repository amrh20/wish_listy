import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_state.dart';

/// Privacy-first profile image action bottom sheet.
/// Only two options: Choose from Gallery and Remove Photo.
/// No camera option - uses Android Photo Picker on Android 13+ without manifest permissions.
class ProfileImageActionBottomSheet extends StatelessWidget {
  final String? currentImageUrl;
  final bool hasUploadedImage;

  const ProfileImageActionBottomSheet({
    super.key,
    this.currentImageUrl,
    required this.hasUploadedImage,
  });

  static void show(
    BuildContext context, {
    required String? currentImageUrl,
    required bool hasUploadedImage,
  }) {
    final profileCubit = context.read<ProfileCubit>();
    profileCubit.setCurrentProfileImage(currentImageUrl);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider<ProfileCubit>.value(
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
    final localization = Provider.of<LocalizationService>(context);
    final cubit = context.read<ProfileCubit>();

    return BlocConsumer<ProfileCubit, ProfileImageState>(
      listener: (context, state) {
        if (state is ProfileImageUploadSuccess || state is ProfileImageDeleteSuccess) {
          Navigator.of(context).pop();
        } else if (state is ProfileImageUploadError || state is ProfileImageDeleteError) {
          final message = state is ProfileImageUploadError
              ? state.message
              : (state as ProfileImageDeleteError).message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileImageUploading || state is ProfileImageDeleting;

        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localization.translate('profile.changeProfilePicture') ??
                    'Change Profile Picture',
                style: AppStyles.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Choose from Gallery
              CustomButton(
                text: localization.translate('profile.chooseFromGallery') ??
                    'Choose from Gallery',
                onPressed: isLoading ? null : () => cubit.pickImageFromGallery(),
                variant: ButtonVariant.outline,
                icon: Icons.photo_library_outlined,
                isLoading: state is ProfileImageUploading,
              ),
              const SizedBox(height: 12),
              // Remove Photo (only if user has a profile image)
              if (hasUploadedImage) ...[
                CustomButton(
                  text: localization.translate('profile.removePhoto') ?? 'Remove Photo',
                  onPressed: isLoading ? null : () => cubit.deleteProfileImage(),
                  variant: ButtonVariant.outline,
                  icon: Icons.delete_outline,
                  isLoading: state is ProfileImageDeleting,
                  customColor: AppColors.error,
                  customTextColor: AppColors.error,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}
