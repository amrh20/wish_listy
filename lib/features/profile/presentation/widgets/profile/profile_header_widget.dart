import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/widgets/royal_avatar_wrapper.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_state.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile_image_action_bottom_sheet.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String? profileImage;
  final String? userBio;
  final String? userHandle;
  final VoidCallback onEditPersonalInfo;
  final Function(BuildContext, String) onShowFullScreenImage;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    this.profileImage,
    this.userBio,
    this.userHandle,
    required this.onEditPersonalInfo,
    required this.onShowFullScreenImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasBio = userBio != null && userBio!.trim().isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 0),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with BlocBuilder for upload/delete states
              BlocBuilder<ProfileCubit, ProfileImageState>(
                builder: (context, state) {
                  final isUploading = state is ProfileImageUploading;
                  final isDeleting = state is ProfileImageDeleting;
                  final isLoading = isUploading || isDeleting;

                  String? currentProfileImage = profileImage;
                  if (state is ProfileImageUploadSuccess) {
                    currentProfileImage = state.imageUrl;
                  } else if (state is ProfileImageDeleteSuccess) {
                    currentProfileImage = null;
                  }

                  final hasUploadedImage = currentProfileImage != null &&
                      currentProfileImage.isNotEmpty &&
                      !currentProfileImage.contains('placeholder') &&
                      !currentProfileImage.contains('default');

                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Hero(
                          tag: 'profile_image_${currentProfileImage ?? 'placeholder'}',
                          child: GestureDetector(
                            onTap: currentProfileImage != null &&
                                    currentProfileImage.isNotEmpty
                                ? () => onShowFullScreenImage(
                                    context, currentProfileImage!)
                                : null,
                            child: RoyalAvatarWrapper(
                              userName: userName,
                              crownSize: 34,
                              topOffset: -28,
                              child: ClipOval(
                                child: _buildAvatarContent(currentProfileImage),
                              ),
                            ),
                          ),
                        ),
                        // Pink Edit Icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              context
                                  .read<ProfileCubit>()
                                  .setCurrentProfileImage(currentProfileImage);
                              ProfileImageActionBottomSheet.show(
                                context,
                                currentImageUrl: currentProfileImage,
                                hasUploadedImage: hasUploadedImage,
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                hasUploadedImage
                                    ? Icons.edit_outlined
                                    : Icons.photo_library_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        if (isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                userName.isNotEmpty ? userName : 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              // Handle
              if (userHandle != null && userHandle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  userHandle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Bio
              if (hasBio) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    userBio!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.8),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String? currentProfileImage) {
    if (currentProfileImage != null && currentProfileImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: currentProfileImage,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 100,
          height: 100,
          color: Colors.white,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 100,
          height: 100,
          color: Colors.white,
          child: Icon(
            Icons.person,
            size: 60,
            color: AppColors.primary.withOpacity(0.5),
          ),
        ),
      );
    }
    
    return Container(
      width: 100,
      height: 100,
      color: Colors.white,
      child: Icon(
        Icons.person,
        size: 60,
        color: AppColors.primary.withOpacity(0.5),
      ),
    );
  }
}

