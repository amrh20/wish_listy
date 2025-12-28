import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/profile/presentation/providers/activity_provider.dart';
import 'package:wish_listy/features/profile/presentation/widgets/activity_card.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    provider.fetchActivities();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasNextPage) {
        provider.loadMoreActivities();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Happening Now ⚡',
          style: AppStyles.headingMedium,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: AppColors.primary,
            child: provider.isLoading && provider.activities.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : provider.hasError && provider.activities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.errorMessage ?? 'Failed to load activities',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.fetchActivities(isRefresh: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : provider.activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recent activity',
                                  style: AppStyles.bodyLarge.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Activity from your friends will appear here',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            itemCount: provider.activities.length +
                                (provider.isLoadingMore ? 1 : 0) +
                                (!provider.hasNextPage && provider.activities.isNotEmpty ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show loading indicator at bottom
                              if (index == provider.activities.length && provider.isLoadingMore) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }
                              
                              // Show "No more updates" message at the end
                              if (index == provider.activities.length && 
                                  !provider.hasNextPage && 
                                  provider.activities.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Center(
                                    child: Text(
                                      'No more updates from the last 15 days',
                                      style: AppStyles.bodySmall.copyWith(
                                        color: AppColors.textTertiary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final activity = provider.activities[index];
                              return ActivityCard(activity: activity);
                            },
                          ),
          );
        },
      ),
    );
  }
}

