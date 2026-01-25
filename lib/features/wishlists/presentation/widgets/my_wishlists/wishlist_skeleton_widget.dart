import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';

/// Skeleton loading list for wishlist cards (used in my_wishlists loading state).
class WishlistSkeletonWidget extends StatelessWidget {
  final AnimationController animationController;
  final Future<void> Function() onRefresh;

  const WishlistSkeletonWidget({
    super.key,
    required this.animationController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final pulseValue = 0.15 +
            (0.2 *
                (0.5 +
                    0.5 * (1 + (2 * animationController.value - 1).abs())));

        return RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.primary,
          child: ListView.separated(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom + 100,
            ),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, __) => _WishlistCardSkeleton(pulseValue: pulseValue),
          ),
        );
      },
    );
  }
}

class _WishlistCardSkeleton extends StatelessWidget {
  final double pulseValue;

  const _WishlistCardSkeleton({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textTertiary.withOpacity(0.05),
              offset: const Offset(0, 5),
              blurRadius: 15,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.08 + pulseValue * 0.05),
                          AppColors.primary.withOpacity(0.12 + pulseValue * 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.1 + pulseValue * 0.05,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.08 + pulseValue * 0.03,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1 + pulseValue * 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatSkeleton(pulseValue: pulseValue),
                      _StatSkeleton(pulseValue: pulseValue),
                      _StatSkeleton(pulseValue: pulseValue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.06 + pulseValue * 0.03,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.06 + pulseValue * 0.03,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.06 + pulseValue * 0.03,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  final double pulseValue;

  const _StatSkeleton({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06 + pulseValue * 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1 + pulseValue * 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08 + pulseValue * 0.03),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
