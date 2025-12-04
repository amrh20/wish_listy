import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';

class CreateWishlistScreen extends StatefulWidget {
  final String? wishlistId;

  const CreateWishlistScreen({super.key, this.wishlistId});

  @override
  State<CreateWishlistScreen> createState() => _CreateWishlistScreenState();
}

class _CreateWishlistScreenState extends State<CreateWishlistScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isFormValid = false; // Track if form is valid
  String _selectedPrivacy = 'public';
  String _selectedCategory = 'birthday';
  bool _isCustomCategory = false;
  final WishlistRepository _wishlistRepository = WishlistRepository();

  final List<String> _privacyOptions = ['public', 'private', 'friends'];
  final List<String> _categoryOptions = [
    'birthday',
    'wedding',
    'graduation',
    'anniversary',
    'babyShower',
    'christmas',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 CreateWishlistScreen: initState');
    debugPrint('   WishlistId: ${widget.wishlistId}');
    debugPrint('   Is Editing: ${widget.wishlistId != null}');

    _initializeAnimations();
    // Add listeners to form fields
    _nameController.addListener(_validateForm);
    _customCategoryController.addListener(_validateForm);
    // Load wishlist data if editing
    if (widget.wishlistId != null) {
      debugPrint('📥 CreateWishlistScreen: Loading wishlist data...');
      _loadWishlistData();
    } else {
      debugPrint('📝 CreateWishlistScreen: Creating new wishlist');
    }
  }

  /// Validate form and update _isFormValid state
  void _validateForm() {
    final name = _nameController.text.trim();
    final isNameValid =
        name.isNotEmpty && name.length >= 2 && name.length <= 100;

    final isCustomCategoryValid =
        !_isCustomCategory ||
        (_customCategoryController.text.trim().isNotEmpty &&
            _customCategoryController.text.trim().length >= 2 &&
            _customCategoryController.text.trim().length <= 50);

    final isValid = isNameValid && isCustomCategoryValid;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
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
    _nameController.removeListener(_validateForm);
    _customCategoryController.removeListener(_validateForm);
    _nameController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
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
                  widget.wishlistId != null
                      ? 'Edit Wishlist'
                      : localization.translate('wishlists.createWishlist'),
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
              final isCustom = category == 'custom';

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _isCustomCategory = category == 'custom';
                    if (category != 'custom') {
                      _customCategoryController.clear();
                    }
                  });
                  _validateForm(); // Revalidate when category changes
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
                        : isCustom
                        ? AppColors.surfaceVariant.withOpacity(0.5)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: isCustom && !isSelected
                        ? Border.all(
                            color: AppColors.primary.withOpacity(0.4),
                            width: 1.5,
                            style: BorderStyle.solid,
                          )
                        : Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textTertiary.withOpacity(0.3),
                            width: 1,
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCustom && !isSelected)
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.primary,
                        )
                      else if (isCustom && isSelected)
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                      if (isCustom) const SizedBox(width: 6),
                      Text(
                        _getCategoryDisplayName(category, localization),
                        style: AppStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : isCustom
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected || isCustom
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Show custom category input field when "Custom" is selected
          if (_isCustomCategory) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: _customCategoryController,
              label: 'Custom Category',
              hint: 'Enter your custom category name',
              prefixIcon: Icons.edit_outlined,
              validator: (value) {
                if (_isCustomCategory && (value?.isEmpty ?? true)) {
                  return 'Please enter a custom category name';
                }
                if (_isCustomCategory &&
                    value != null &&
                    value.trim().length < 2) {
                  return 'Category name must be at least 2 characters';
                }
                if (_isCustomCategory &&
                    value != null &&
                    value.trim().length > 50) {
                  return 'Category name must be less than 50 characters';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(LocalizationService localization) {
    final isEditing = widget.wishlistId != null;
    return Column(
      children: [
        CustomButton(
          text: isEditing
              ? 'Update Wishlist'
              : localization.translate('wishlists.createWishlist'),
          onPressed: _isFormValid && !_isLoading
              ? () => _createWishlist(localization)
              : null,
          isLoading: _isLoading,
          variant: ButtonVariant.gradient,
          gradientColors: [AppColors.primary, AppColors.secondary],
          icon: isEditing ? Icons.save_rounded : Icons.favorite_rounded,
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
      case 'friends':
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
      case 'friends':
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
      case 'friends':
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
      case 'babyShower':
        return 'Baby Shower';
      case 'housewarming':
        return 'Housewarming';
      case 'custom':
        return 'Other';
      default:
        return category;
    }
  }

  /// Load wishlist data when editing
  Future<void> _loadWishlistData() async {
    if (widget.wishlistId == null) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('📥 Loading wishlist data for editing: ${widget.wishlistId}');
      final wishlistData = await _wishlistRepository.getWishlistById(
        widget.wishlistId!,
      );

      debugPrint('✅ Wishlist data loaded: $wishlistData');

      // Populate form fields
      if (mounted) {
        final category = wishlistData['category']?.toString() ?? 'general';
        final isPredefinedCategory =
            _categoryOptions.contains(category) && category != 'custom';

        setState(() {
          _nameController.text = wishlistData['name']?.toString() ?? '';
          _descriptionController.text =
              wishlistData['description']?.toString() ?? '';
          _selectedPrivacy = wishlistData['privacy']?.toString() ?? 'public';

          if (isPredefinedCategory) {
            _selectedCategory = category;
            _isCustomCategory = false;
            _customCategoryController.clear();
          } else {
            // It's a custom category
            _selectedCategory = 'custom';
            _isCustomCategory = true;
            _customCategoryController.text = category;
          }
          _isLoading = false;
        });
        // Validate form after loading data
        _validateForm();
      }
    } on ApiException catch (e) {
      debugPrint('❌ Error loading wishlist: ${e.message}');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load wishlist: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Unexpected error loading wishlist: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load wishlist. Please try again.');
      }
    }
  }

  Future<void> _createWishlist(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    final isEditing = widget.wishlistId != null;

    // Determine the final category value
    final finalCategory = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    // Validate custom category if selected
    if (_isCustomCategory && finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a custom category name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    debugPrint('🚀 Starting wishlist ${isEditing ? "update" : "creation"}...');
    debugPrint('   Name: ${_nameController.text.trim()}');
    debugPrint('   Description: ${_descriptionController.text.trim()}');
    debugPrint('   Privacy: $_selectedPrivacy');
    debugPrint('   Category: $finalCategory (isCustom: $_isCustomCategory)');

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        // Update existing wishlist
        debugPrint('📡 Calling API: PUT /api/wishlists/${widget.wishlistId}');
        final response = await _wishlistRepository.updateWishlist(
          wishlistId: widget.wishlistId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          privacy: _selectedPrivacy,
          category: finalCategory,
        );

        debugPrint('✅ API Response received: $response');

        setState(() => _isLoading = false);

        // Check if update was successful
        if (response['success'] == true ||
            response['data'] != null ||
            response['wishlist'] != null) {
          // Show success message and navigate back
          if (mounted) {
            _showSuccessAndNavigate(localization, widget.wishlistId!);
          }
        } else {
          // Update failed
          final errorMessage =
              response['message']?.toString() ??
              'Failed to update wishlist. Please try again.';
          if (mounted) {
            _showErrorSnackBar(errorMessage);
          }
        }
      } else {
        // Create new wishlist
        debugPrint('📡 Calling API: POST /api/wishlists');
        final response = await _wishlistRepository.createWishlist(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          privacy: _selectedPrivacy,
          category: finalCategory,
        );

        debugPrint('✅ API Response received: $response');

        setState(() => _isLoading = false);

        // Check if creation was successful
        if (response['success'] == true || response['data'] != null) {
          // Extract wishlist ID from response - try multiple possible formats
          final wishlistData =
              response['data'] ?? response['wishlist'] ?? response;

          // Try to get ID from various possible locations
          String? wishlistId =
              wishlistData['id']?.toString() ??
              wishlistData['wishlistId']?.toString() ??
              wishlistData['_id']?.toString() ??
              response['id']?.toString() ??
              response['wishlistId']?.toString();

          debugPrint(
            '🔍 CreateWishlistScreen: Extracted wishlist ID: $wishlistId',
          );
          debugPrint('   Full response: $response');
          debugPrint('   Wishlist data: $wishlistData');

          // If we couldn't find the ID, show error instead of using fake ID
          if (wishlistId == null || wishlistId.isEmpty) {
            debugPrint(
              '❌ CreateWishlistScreen: Could not extract wishlist ID from response',
            );
            if (mounted) {
              _showErrorSnackBar(
                'Wishlist created but could not get ID. Please refresh the wishlists page.',
              );
            }
            return;
          }

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
      debugPrint('${isEditing ? "Update" : "Create"} wishlist error: $e');
    }
  }

  /// Show error message as a dialog with Lottie animation
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ConfirmationDialog.show(
      context: context,
      isSuccess: false,
      title: 'Failed to Create Wishlist',
      message: message,
      primaryActionLabel: 'Try Again',
      onPrimaryAction: () {
        // User can try again by submitting the form again
      },
      secondaryActionLabel: 'Close',
      onSecondaryAction: () {},
      barrierDismissible: true,
    );
  }

  void _showSuccessAndNavigate(
    LocalizationService localization,
    String wishlistId,
  ) {
    if (widget.wishlistId != null) {
      // Editing mode - simple success dialog
      ConfirmationDialog.show(
        context: context,
        isSuccess: true,
        title: 'Wishlist Updated!',
        message: 'Your wishlist has been updated successfully.',
        primaryActionLabel: 'Done',
        onPrimaryAction: () {
          Navigator.of(
            context,
          ).pop(true); // Return to previous screen with result
        },
      );
    } else {
      // Creating mode - success dialog with multiple actions
      ConfirmationDialog.show(
        context: context,
        isSuccess: true,
        title: localization.translate('wishlists.wishlistCreatedTitle'),
        message: localization.translate('wishlists.wishlistCreatedMessage'),
        backgroundVectorPath:
            'assets/images/Wishes-amico.png', // Background vector
        primaryActionLabel: localization.translate(
          'wishlists.addItemsToWishlist',
        ),
        onPrimaryAction: () {
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
        additionalActions: [
          DialogAction(
            label: localization.translate('wishlists.viewWishlist'),
            onPressed: () async {
              // Close dialog first
              Navigator.of(context).pop();

              // Show loading indicator
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
              }

              try {
                debugPrint(
                  '🔍 CreateWishlistScreen: Viewing wishlist with ID: $wishlistId',
                );

                // Call API to get wishlist details
                final wishlistData = await _wishlistRepository.getWishlistById(
                  wishlistId,
                );

                debugPrint(
                  '✅ CreateWishlistScreen: Received wishlist data: $wishlistData',
                );

                // Close loading dialog
                if (mounted) {
                  Navigator.of(context).pop();
                }

                // Extract wishlist information from API response
                final data =
                    wishlistData['wishlist'] as Map<String, dynamic>? ??
                    wishlistData['data'] as Map<String, dynamic>? ??
                    wishlistData;
                final wishlistName =
                    data['name']?.toString() ?? _nameController.text;
                final itemsList = data['items'] as List<dynamic>? ?? [];
                final totalItems = itemsList.length;
                final purchasedItems = itemsList.where((item) {
                  final itemMap = item as Map<String, dynamic>;
                  return itemMap['status']?.toString().toLowerCase() ==
                          'purchased' ||
                      itemMap['purchased'] == true;
                }).length;

                debugPrint(
                  '📊 CreateWishlistScreen: Navigating with - Name: $wishlistName, Items: $totalItems, Purchased: $purchasedItems',
                );

                // Navigate to wishlist items screen with actual data from API
                if (mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.wishlistItems,
                    arguments: {
                      'wishlistId': wishlistId,
                      'wishlistName': wishlistName,
                      'totalItems': totalItems,
                      'purchasedItems': purchasedItems,
                      'isFriendWishlist': false,
                    },
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) {
                  Navigator.of(context).pop();
                }

                debugPrint(
                  '❌ CreateWishlistScreen: Error loading wishlist details',
                );
                debugPrint('   Wishlist ID: $wishlistId');
                debugPrint('   Error: $e');

                // Show error message with more context
                if (mounted) {
                  final errorMessage = e is ApiException
                      ? e.message
                      : 'Failed to load wishlist details. The wishlist was created successfully. Please go back and refresh the wishlists page.';

                  _showErrorSnackBar(errorMessage);
                }
              }
            },
            variant: ButtonVariant.outline,
            icon: Icons.visibility_rounded,
          ),
          DialogAction(
            label: localization.translate('wishlists.createAnotherWishlist'),
            onPressed: () {
              // Reset form
              _nameController.clear();
              _descriptionController.clear();
              _customCategoryController.clear();
              setState(() {
                _selectedPrivacy = 'public';
                _selectedCategory = 'general';
                _isCustomCategory = false;
              });
            },
            variant: ButtonVariant.text,
            icon: Icons.add_circle_outline,
          ),
        ],
      );
    }
  }
}
