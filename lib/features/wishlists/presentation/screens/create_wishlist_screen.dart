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
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';

class CreateWishlistScreen extends StatefulWidget {
  const CreateWishlistScreen({super.key});

  @override
  State<CreateWishlistScreen> createState() => _CreateWishlistScreenState();
}

class _CreateWishlistScreenState extends State<CreateWishlistScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String _selectedPrivacy = 'public';
  String _selectedCategory = 'general';
  final WishlistRepository _wishlistRepository = WishlistRepository();

  final List<String> _privacyOptions = ['public', 'private', 'friendsOnly'];
  final List<String> _categoryOptions = [
    'general',
    'birthday',
    'wedding',
    'graduation',
    'anniversary',
    'holiday',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: DecorativeBackground(
            showGifts: true,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(localization),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),

                                // Wishlist Name
                                CustomTextField(
                                  controller: _nameController,
                                  label: localization.translate(
                                    'wishlists.wishlistName',
                                  ),
                                  hint: localization.translate(
                                    'wishlists.wishlistName',
                                  ),
                                  prefixIcon: Icons.favorite_outline,
                                  isRequired: true,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      final errorMsg = localization.translate(
                                        'wishlists.wishlistNameRequired',
                                      );
                                      return errorMsg.isNotEmpty
                                          ? errorMsg
                                          : 'Wishlist name is required';
                                    }
                                    if (value!.trim().length < 2) {
                                      return 'Wishlist name must be at least 2 characters';
                                    }
                                    if (value.trim().length > 100) {
                                      return 'Wishlist name must be less than 100 characters';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Description
                                CustomTextField(
                                  controller: _descriptionController,
                                  label: localization.translate(
                                    'wishlists.description',
                                  ),
                                  hint: localization.translate(
                                    'wishlists.wishlistDescriptionOptional',
                                  ),
                                  prefixIcon: Icons.description_outlined,
                                  maxLines: 3,
                                  validator: (value) {
                                    // Description is optional, but if provided, validate length
                                    if (value != null && value.isNotEmpty) {
                                      if (value.trim().length > 500) {
                                        return 'Description must be less than 500 characters';
                                      }
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Privacy Selection
                                _buildPrivacySelection(localization),

                                const SizedBox(height: 24),

                                // Category Selection
                                _buildCategorySelection(localization),

                                const SizedBox(height: 40),

                                // Action Buttons
                                _buildActionButtons(localization),

                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
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
                  localization.translate('wishlists.createWishlist'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  localization.translate(
                    'wishlists.wishlistDescriptionOptional',
                  ),
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

  Widget _buildPrivacySelection(LocalizationService localization) {
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
          Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('wishlists.privacy'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: _privacyOptions.map((privacy) {
              final isSelected = _selectedPrivacy == privacy;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPrivacy = privacy;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPrivacyIcon(privacy),
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPrivacyTitle(privacy, localization),
                              style: AppStyles.bodyMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              _getPrivacyDescription(privacy, localization),
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection(LocalizationService localization) {
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
              Icon(
                Icons.category_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('wishlists.category'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoryOptions.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondary
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getCategoryDisplayName(category, localization),
                    style: AppStyles.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
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

  Widget _buildActionButtons(LocalizationService localization) {
    return Column(
      children: [
        CustomButton(
          text: localization.translate('wishlists.createWishlist'),
          onPressed: () => _createWishlist(localization),
          isLoading: _isLoading,
          variant: ButtonVariant.gradient,
          gradientColors: [AppColors.primary, AppColors.secondary],
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: localization.translate('common.cancel'),
          onPressed: () => Navigator.pop(context),
          variant: ButtonVariant.outline,
        ),
      ],
    );
  }

  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock;
      case 'friendsOnly':
        return Icons.people;
      default:
        return Icons.public;
    }
  }

  String _getPrivacyTitle(String privacy, LocalizationService localization) {
    switch (privacy) {
      case 'public':
        return localization.translate('wishlists.public');
      case 'private':
        return localization.translate('wishlists.private');
      case 'friendsOnly':
        return localization.translate('wishlists.friendsOnly');
      default:
        return privacy;
    }
  }

  String _getPrivacyDescription(
    String privacy,
    LocalizationService localization,
  ) {
    switch (privacy) {
      case 'public':
        return localization.translate('events.publicDescription');
      case 'private':
        return localization.translate('events.privateDescription');
      case 'friendsOnly':
        return localization.translate('events.friendsOnlyDescription');
      default:
        return '';
    }
  }

  String _getCategoryDisplayName(
    String category,
    LocalizationService localization,
  ) {
    switch (category) {
      case 'general':
        return localization.translate('common.general');
      case 'birthday':
        return localization.translate('events.birthday');
      case 'wedding':
        return localization.translate('events.wedding');
      case 'graduation':
        return localization.translate('events.graduation');
      case 'anniversary':
        return localization.translate('events.anniversary');
      case 'holiday':
        return localization.translate('common.holiday');
      default:
        return category;
    }
  }

  Future<void> _createWishlist(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    debugPrint('🚀 Starting wishlist creation...');
    debugPrint('   Name: ${_nameController.text.trim()}');
    debugPrint('   Description: ${_descriptionController.text.trim()}');
    debugPrint('   Privacy: $_selectedPrivacy');
    debugPrint('   Category: $_selectedCategory');

    setState(() => _isLoading = true);

    try {
      // Call API to create wishlist
      debugPrint('📡 Calling API: POST /api/wishlists');
      final response = await _wishlistRepository.createWishlist(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        privacy: _selectedPrivacy,
        category: _selectedCategory,
      );

      debugPrint('✅ API Response received: $response');

      setState(() => _isLoading = false);

      // Check if creation was successful
      if (response['success'] == true || response['data'] != null) {
        // Extract wishlist ID from response
        final wishlistData = response['data'] ?? response;
        final wishlistId =
            wishlistData['id']?.toString() ??
            wishlistData['wishlistId']?.toString() ??
            'new_wishlist_id';

        // Show success message and navigate
        if (mounted) {
          _showSuccessAndNavigate(localization, wishlistId);
        }
      } else {
        // Creation failed
        final errorMessage =
            response['message']?.toString() ??
            'Failed to create wishlist. Please try again.';
        if (mounted) {
          _showErrorSnackBar(errorMessage);
        }
      }
    } on ApiException catch (e) {
      // Handle API-specific errors
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      // Handle unexpected errors
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
      debugPrint('Create wishlist error: $e');
    }
  }

  /// Show error message as a top toast
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessAndNavigate(
    LocalizationService localization,
    String wishlistId,
  ) {
    // Show success dialog with action options
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              localization.translate('wishlists.wishlistCreatedTitle'),
              style: AppStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              localization.translate('wishlists.wishlistCreatedMessage'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                // Add Items Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: localization.translate(
                      'wishlists.addItemsToWishlist',
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.addItem,
                        arguments: {
                          'wishlistId': wishlistId,
                          'wishlistName': _nameController.text,
                          'isNewWishlist': true,
                        },
                      );
                    },
                    variant: ButtonVariant.gradient,
                    gradientColors: [AppColors.primary, AppColors.secondary],
                    icon: Icons.add_rounded,
                  ),
                ),
                const SizedBox(height: 12),

                // View Wishlist Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: localization.translate('wishlists.viewWishlist'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.wishlistItems,
                        arguments: {
                          'wishlistId': wishlistId,
                          'wishlistName': _nameController.text,
                          'totalItems': 0,
                          'purchasedItems': 0,
                          'isFriendWishlist': false,
                        },
                      );
                    },
                    variant: ButtonVariant.outline,
                    icon: Icons.visibility_rounded,
                  ),
                ),
                const SizedBox(height: 12),

                // Create Another Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: localization.translate(
                      'wishlists.createAnotherWishlist',
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Reset form
                      _nameController.clear();
                      _descriptionController.clear();
                      setState(() {
                        _selectedPrivacy = 'public';
                        _selectedCategory = 'general';
                      });
                    },
                    variant: ButtonVariant.text,
                    icon: Icons.add_circle_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
