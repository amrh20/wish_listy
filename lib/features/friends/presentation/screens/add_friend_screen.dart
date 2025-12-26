import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/friends/data/models/user_model.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  final FriendsRepository _friendsRepository = FriendsRepository();
  Timer? _debounceTimer;

  bool _isSearching = false;
  String _searchMethod = 'email'; // Default to email
  List<User> _searchResults = [];
  String? _searchError;

  // Track which user is currently sending a request (for loading state)
  String? _sendingRequestToUserId;

  final List<String> _searchMethods = ['email', 'phone']; // Removed username

  @override
  void initState() {
    super.initState();
    // Removed auto-search listener - search only happens on button tap
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Perform search when search button is tapped
  void _onSearchButtonTap() {
    final query = _searchController.text.trim();
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _searchResults.clear();
        _searchError = null;
        _isSearching = false;
      });
      return;
    }
    _performSearch(query);
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

                          // Search Field with Search Button
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _searchController,
                                  label: _getSearchLabel(localization),
                                  hint: _getSearchHint(localization),
                                  prefixIcon: Icons.search,
                                  // We only show the main loader in the results section
                                  // to avoid multiple spinners on the screen.
                                  suffixIcon: null,
                                  onChanged: (value) {
                                    // No auto-search - only search on button tap
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Search Button
                              ElevatedButton(
                                onPressed: _isSearching ? null : _onSearchButtonTap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  minimumSize: const Size(0, 48),
                                ),
                                // Keep the label static; rely only on the results loader
                                // so we don't show multiple loading indicators.
                                child: Text(
                                  localization.translate('friends.searchButton'),
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Search Results
                          if (_searchController.text.isNotEmpty &&
                              _searchController.text.length >= 2) ...[
                            _buildSearchResults(localization),
                            const SizedBox(height: 32),
                          ],

                          // Empty State - Show when no search is performed
                          if (_searchController.text.isEmpty ||
                              _searchController.text.length < 2) ...[
                            _buildEmptySearchState(localization),
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
      child: Text(
        localization.translate('friends.searchFriends'),
        style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSearchResults(LocalizationService localization) {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _searchError!,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No users found',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

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
                '${_searchResults.length} ${localization.translate('friends.searchResults')}',
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
    User user,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and user info row
          Row(
            children: [
              // Clickable Avatar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToFriendProfile(user),
                  borderRadius: BorderRadius.circular(24),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: AppStyles.headingSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clickable Name
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _navigateToFriendProfile(user),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            user.fullName,
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (user.username.isNotEmpty)
                      Text(
                        '@${user.username}',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (user.mutualFriendsCount != null && user.mutualFriendsCount! > 0)
                      Text(
                        localization.translate(
                          'friends.mutualFriendsCount',
                          args: {'count': user.mutualFriendsCount.toString()},
                        ),
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    // Show status message under the name if canSendRequest is false
                    // But don't show message if status is 'received' (we'll show buttons instead)
                    if (user.canSendRequest == false && user.friendshipStatus != 'received')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildRequestStatusMessage(user, localization),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Action buttons row at the bottom
          if (user.friendshipStatus == 'received') ...[
            // Accept/Reject buttons for received friend requests
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => _handleFriendRequestAction(user, false, localization),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withOpacity(0.5),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        localization.translate('friends.reject'),
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _handleFriendRequestAction(user, true, localization),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        localization.translate('friends.accept'),
                        style: AppStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (user.canSendRequest != false) ...[
            // Send Request button with purple gradient design
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _sendingRequestToUserId == user.id ? null : () => _sendFriendRequest(user, localization),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  // Ensure text is never clipped
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: _sendingRequestToUserId == user.id
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                child: Text(
                  localization.translate('friends.sendRequest'),
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build status message when friend request cannot be sent
  Widget _buildRequestStatusMessage(
    User user,
    LocalizationService localization,
  ) {
    // Determine message and color based on friendship status
    String messageKey;
    Color textColor;
    
    switch (user.friendshipStatus) {
      case 'received':
        // User received a request from this person
        messageKey = 'requestReceived';
        textColor = AppColors.primary;
        break;
      case 'pending':
        // Request already sent
        messageKey = 'requestPending';
        textColor = AppColors.warning;
        break;
      case 'accepted':
        // Already friends
        messageKey = 'alreadyFriends';
        textColor = AppColors.success;
        break;
      default:
        // Default message
        messageKey = 'requestAlreadySent';
        textColor = AppColors.textSecondary;
    }

    return Text(
      localization.translate('friends.$messageKey'),
      style: AppStyles.bodySmall.copyWith(
        color: textColor,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmptySearchState(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Search for Friends',
            style: AppStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter an email or phone number to find and connect with your friends',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedFriends(LocalizationService localization) {
    // TODO: Load friend suggestions from API
    // This will be implemented when we add getFriendSuggestions API
    return const SizedBox.shrink();
  }

  IconData _getSearchMethodIcon(String method) {
    switch (method) {
      case 'email':
        return Icons.email;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.email;
    }
  }

  String _getSearchMethodName(String method, LocalizationService localization) {
    switch (method) {
      case 'email':
        return localization.translate('friends.email');
      case 'phone':
        return localization.translate('auth.phone');
      default:
        return method;
    }
  }

  String _getSearchLabel(LocalizationService localization) {
    // Unified label for email/phone search
    return 'Email / Phone';
  }

  String _getSearchHint(LocalizationService localization) {
    // Simple hint explaining accepted input types
    return 'Enter email address or phone number';
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _searchResults.clear();
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      // Always use 'username' as type, but send the actual value (email or phone)
      final users = await _friendsRepository.searchUsers(
        type: 'username', // Always username type
        value: query, // The actual value (email or phone number)
      );

      if (mounted) {
        final timestamp = DateTime.now().toIso8601String();
        debugPrint('👥 [AddFriend] ⏰ [$timestamp] Search completed');
        debugPrint('👥 [AddFriend] ⏰ [$timestamp]    Total results from API: ${users.length}');
        
        // Filter out users who are already friends (isFriend: true)
        final filteredUsers = users.where((user) {
          final isAlreadyFriend = user.isFriend == true;
          if (isAlreadyFriend) {
            debugPrint('👥 [AddFriend] ⏰ [$timestamp]    Filtering out friend: ${user.fullName} (${user.username})');
          }
          return !isAlreadyFriend;
        }).toList();
        
        debugPrint('👥 [AddFriend] ⏰ [$timestamp]    Filtered results (excluding friends): ${filteredUsers.length}');
        debugPrint('👥 [AddFriend] ⏰ [$timestamp]    Removed ${users.length - filteredUsers.length} friend(s) from results');
        
        setState(() {
          _searchResults = filteredUsers;
          _isSearching = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.message;
          _searchResults.clear();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Failed to search users. Please try again.';
          _searchResults.clear();
          _isSearching = false;
        });
      }

    }
  }

  Future<void> _sendFriendRequest(
    User user,
    LocalizationService localization,
  ) async {
    // Set loading state
    setState(() {
      _sendingRequestToUserId = user.id;
    });
    
    try {
      final response = await _friendsRepository.sendFriendRequest(
        toUserId: user.id,
        message: null, // Optional message
      );

      if (mounted) {
        final timestamp = DateTime.now().toIso8601String();
        debugPrint('👥 [AddFriend] ⏰ [$timestamp] Friend request sent successfully');
        debugPrint('👥 [AddFriend] ⏰ [$timestamp]    User ID: ${user.id}');
        debugPrint('👥 [AddFriend] ⏰ [$timestamp]    User Name: ${user.fullName}');
        debugPrint('👥 [AddFriend] ⏰ [$timestamp]    Updating UI to show "Request already sent"');
        
        // Update the user in search results to reflect that request was sent
        setState(() {
          _sendingRequestToUserId = null; // Clear loading state
          final index = _searchResults.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _searchResults[index] = user.copyWith(
              friendshipStatus: 'pending',
              canSendRequest: false,
            );
            debugPrint('👥 [AddFriend] ⏰ [$timestamp]    ✅ User updated in search results at index $index');
            debugPrint('👥 [AddFriend] ⏰ [$timestamp]       New status: pending');
            debugPrint('👥 [AddFriend] ⏰ [$timestamp]       Can send request: false');
          } else {
            debugPrint('👥 [AddFriend] ⏰ [$timestamp]    ⚠️ User not found in search results');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localization.translate('friends.friendRequestSent')} to ${user.fullName}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _sendingRequestToUserId = null; // Clear loading state on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendingRequestToUserId = null; // Clear loading state on error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send friend request. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

    }
  }

  /// Handle friend request action (accept/reject)
  Future<void> _handleFriendRequestAction(
    User user,
    bool accept,
    LocalizationService localization,
  ) async {
    // Extract requestId from user model
    final requestId = user.requestId;
    
    if (requestId == null || requestId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  localization.translate('friends.requestIdNotFound') ?? 
                  'Unable to process friend request. Request ID not found.',
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }
    
    try {
      if (accept) {
        await _friendsRepository.acceptFriendRequest(requestId: requestId);
      } else {
        await _friendsRepository.rejectFriendRequest(requestId: requestId);
      }

      if (mounted) {
        // Update the user in search results
        setState(() {
          final index = _searchResults.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _searchResults[index] = user.copyWith(
              friendshipStatus: accept ? 'accepted' : 'none',
              canSendRequest: accept ? false : true,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  accept ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  accept
                      ? localization.translate('friends.friendRequestAccepted')
                      : localization.translate('friends.friendRequestRejected'),
                ),
              ],
            ),
            backgroundColor: accept ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Failed to accept friend request. Please try again.'
                  : 'Failed to reject friend request. Please try again.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Navigate to friend profile screen
  void _navigateToFriendProfile(User user) {
    AppRoutes.pushNamed(
      context,
      AppRoutes.friendProfile,
      arguments: {'friendId': user.id},
    );
  }

}
