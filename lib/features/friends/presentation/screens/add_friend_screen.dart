import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();

  bool _isSearching = false;
  String _searchMethod = 'username';
  List<Map<String, dynamic>> _searchResults = [];

  final List<String> _searchMethods = ['username', 'email', 'phone'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: DecorativeBackground(
            showGifts: true,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(localization),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),

                          // Search Method Selection
                          _buildSearchMethodSelection(localization),

                          const SizedBox(height: 24),

                          // Search Field
                          CustomTextField(
                            controller: _searchController,
                            label: _getSearchLabel(localization),
                            hint: _getSearchHint(localization),
                            prefixIcon: Icons.search,
                            suffixIcon: _isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                            onChanged: (value) {
                              if (value.isNotEmpty && value.length > 2) {
                                _performSearch(value, localization);
                              } else {
                                setState(() {
                                  _searchResults.clear();
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 32),

                          // Search Results
                          if (_searchResults.isNotEmpty) ...[
                            _buildSearchResults(localization),
                            const SizedBox(height: 32),
                          ],

                          // Suggested Friends
                          _buildSuggestedFriends(localization),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('friends.addFriend'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  localization.translate('friends.searchForFriends'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchMethodSelection(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.translate('friends.searchFriends'),
            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: _searchMethods.map((method) {
              final isSelected = _searchMethod == method;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchMethod = method;
                      _searchController.clear();
                      _searchResults.clear();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getSearchMethodIcon(method),
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSearchMethodName(method, localization),
                          style: AppStyles.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('friends.searchResults'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._searchResults
              .map((user) => _buildUserCard(user, localization))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> user,
    LocalizationService localization,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textTertiary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              user['name']?[0]?.toUpperCase() ?? '?',
              style: AppStyles.headingSmall.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user['mutualFriends'] != null)
                  Text(
                    localization.translate(
                      'friends.mutualFriendsCount',
                      args: {'count': user['mutualFriends'].toString()},
                    ),
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: CustomButton(
              text: localization.translate('friends.sendRequest'),
              onPressed: () => _sendFriendRequest(user, localization),
              variant: ButtonVariant.primary,
              size: ButtonSize.small,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSuggestedFriends(LocalizationService localization) {
    final suggestions = [
      {'name': 'Ahmed Ali', 'mutualFriends': 5},
      {'name': 'Sara Mohamed', 'mutualFriends': 3},
      {'name': 'Omar Hassan', 'mutualFriends': 8},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('friends.peopleYouMayKnow'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions
              .map((user) => _buildUserCard(user, localization))
              .toList(),
        ],
      ),
    );
  }

  IconData _getSearchMethodIcon(String method) {
    switch (method) {
      case 'username':
        return Icons.person;
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.person;
    }
  }

  String _getSearchMethodName(String method, LocalizationService localization) {
    switch (method) {
      case 'username':
        return localization.translate('friends.username');
      case 'email':
        return localization.translate('friends.email');
      case 'phone':
        return localization.translate('auth.phone');
      default:
        return method;
    }
  }

  String _getSearchLabel(LocalizationService localization) {
    switch (_searchMethod) {
      case 'username':
        return localization.translate('friends.username');
      case 'email':
        return localization.translate('friends.email');
      case 'phone':
        return localization.translate('auth.phone');
      default:
        return localization.translate('friends.searchFriends');
    }
  }

  String _getSearchHint(LocalizationService localization) {
    switch (_searchMethod) {
      case 'username':
        return localization.translate('friends.searchPlaceholder');
      case 'email':
        return localization.translate('auth.enterEmail');
      case 'phone':
        return localization.translate('auth.phone');
      default:
        return localization.translate('friends.searchPlaceholder');
    }
  }

  Future<void> _performSearch(
    String query,
    LocalizationService localization,
  ) async {
    setState(() => _isSearching = true);

    // Simulate API search
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isSearching = false;
      _searchResults = [
        {'name': 'John Doe', 'mutualFriends': 2},
        {'name': 'Jane Smith', 'mutualFriends': 5},
      ];
    });
  }

  void _sendFriendRequest(
    Map<String, dynamic> user,
    LocalizationService localization,
  ) {
    // Send friend request logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localization.translate('friends.friendRequestSent')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

}
