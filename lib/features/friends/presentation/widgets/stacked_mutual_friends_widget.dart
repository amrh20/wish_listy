import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/friends/data/models/mutual_friends_data_model.dart';

/// Displays stacked mutual friend avatars and a "X mutual friends" label.
/// Returns [SizedBox.shrink()] when [data] is null or [totalCount] is 0.
class StackedMutualFriendsWidget extends StatelessWidget {
  final MutualFriendsData? data;
  /// Avatar size (diameter). Default 28.
  final double avatarSize;
  /// Overlap amount (e.g. 0.35 = 35%). Default 0.35.
  final double overlapRatio;

  const StackedMutualFriendsWidget({
    super.key,
    required this.data,
    this.avatarSize = 28,
    this.overlapRatio = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.totalCount <= 0) {
      return const SizedBox.shrink();
    }

    final preview = data!.preview;
    final totalCount = data!.totalCount;
    final borderColor = Theme.of(context).cardColor ?? AppColors.surface;

    return _buildContent(context, totalCount, preview, borderColor);
  }

  Widget _buildContent(
    BuildContext context,
    int totalCount,
    List<MutualFriendPreview> preview,
    Color borderColor,
  ) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final overlap = avatarSize * overlapRatio;
    final stackWidth = preview.isEmpty
        ? avatarSize
        : avatarSize + (preview.length - 1) * (avatarSize - overlap);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: stackWidth,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(preview.length, (index) {
              final friend = preview[index];
              return Positioned(
                left: index * (avatarSize - overlap),
                child: _AvatarCircle(
                  fullName: friend.fullName,
                  profileImage: friend.profileImage,
                  size: avatarSize,
                  borderColor: borderColor,
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            localization.translate(
              'friends.mutualFriendsCount',
              args: {'count': totalCount.toString()},
            ),
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String fullName;
  final String? profileImage;
  final double size;
  final Color borderColor;

  const _AvatarCircle({
    required this.fullName,
    this.profileImage,
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = profileImage != null && profileImage!.isNotEmpty;
    final trimmed = fullName.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : (trimmed.length >= 2 ? trimmed.substring(0, 2) : trimmed).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        color: AppColors.primary.withOpacity(0.12),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                profileImage!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _InitialFallback(initial: initial, size: size),
              )
            : _InitialFallback(initial: initial, size: size),
      ),
    );
  }
}

class _InitialFallback extends StatelessWidget {
  final String initial;
  final double size;

  const _InitialFallback({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AppColors.primary.withOpacity(0.12),
      child: Text(
        initial,
        style: AppStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
