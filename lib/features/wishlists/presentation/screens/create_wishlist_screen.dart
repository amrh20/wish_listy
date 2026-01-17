import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import '../widgets/create_wishlist_header_widget.dart';
import '../widgets/privacy_selection_widget.dart';
import '../widgets/category_selection_widget.dart';
import '../widgets/create_wishlist_action_buttons_widget.dart';
import '../widgets/wishlist_form_helpers.dart';
import '../widgets/wishlist_success_dialog_helper.dart';

class CreateWishlistScreen extends StatefulWidget {
  final String? wishlistId;
  final String? eventId;
  final bool isForEvent;
  final String? previousRoute;

  const CreateWishlistScreen({
    super.key,
    this.wishlistId,
    this.eventId,
    this.isForEvent = false,
    this.previousRoute,
  });

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
  String? _selectedCategory; // Optional - null means no category selected
  bool _isCustomCategory = false;
  final WishlistRepository _wishlistRepository = WishlistRepository();
  final EventRepository _eventRepository = EventRepository();
  String? _eventName; // Store event name for banner display

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

    _initializeAnimations();
    // Add listeners to form fields
    _nameController.addListener(_validateForm);
    _customCategoryController.addListener(_validateForm);
    // Load wishlist data if editing
    if (widget.wishlistId != null) {
      _loadWishlistData();
    }
    // Load event name if creating for event
    if (widget.isForEvent && widget.eventId != null) {
      _loadEventName();
    }
  }

  /// Handles back navigation - returns to the correct previous screen
  void _handleBackNavigation() {
    if (!mounted) return;

    final previousRoute = widget.previousRoute;

    // Use post-frame callback to ensure Navigator is not locked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Routes that are inside MainNavigation (IndexedStack)
      // These screens don't exist as separate routes, so we just pop to MainNavigation
      final mainNavigationRoutes = [
        AppRoutes.myWishlists,
        AppRoutes.events,
        AppRoutes.friends,
        AppRoutes.profile,
        AppRoutes.home,
        AppRoutes.mainNavigation,
      ];

      // If previousRoute is null or is a MainNavigation route, just pop
      if (previousRoute == null ||
          mainNavigationRoutes.contains(previousRoute)) {

        if (Navigator.of(context).canPop()) {
          try {
            Navigator.of(context).pop();

          } catch (e) {

          }
        }
        return;
      }

      // For other routes (like eventDetails), try to find them in the stack
      bool routeFound = false;
      try {
        // First, try to pop normally - this should work if modal was closed properly
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          routeFound = true;
        } else {
          // If can't pop normally, try popUntil
          Navigator.of(context).popUntil((route) {
            final routeName = route.settings.name;

            if (routeName == previousRoute) {
              routeFound = true;
              return true; // Stop popping
            }
            // Also stop if we reach MainNavigation (to preserve bottom nav)
            if (routeName == AppRoutes.mainNavigation) {
              return true;
            }
            return false; // Continue popping
          });
        }
      } catch (e) {
        routeFound = false;
      }

      // If route not found, just pop (will return to MainNavigation)
      if (!routeFound && mounted) {
        if (Navigator.of(context).canPop()) {
          try {
            Navigator.of(context).pop();
          } catch (e) {
            // Ignore errors
          }
        }
      }
    });
  }

  /// Validate form and update _isFormValid state
  void _validateForm() {
    final name = _nameController.text.trim();
    final isNameValid =
        name.isNotEmpty && name.length >= 2 && name.length <= 100;

    // Only validate custom category if custom category is actually selected
    final isCustomCategoryValid =
        _selectedCategory != 'custom' ||
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
    return Consumer2<LocalizationService, AuthRepository>(
      builder: (context, localization, authService, child) {
        final isGuest = authService.isGuest;
        return Scaffold(
          body: DecorativeBackground(
            showGifts: true,
            child: SafeArea(
              child: Column(
                children: [
                  CreateWishlistHeaderWidget(
                    isEditing: widget.wishlistId != null,
                    onBack: _handleBackNavigation,
                    getTitle: () => widget.wishlistId != null
                        ? 'Edit Wishlist'
                        : localization.translate('wishlists.createWishlist'),
                    getSubtitle: () => widget.wishlistId != null
                        ? localization.translate('wishlists.wishlistDescriptionOptional')
                        : localization.translate('wishlists.createWishlistSubtitle'),
                  ),
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

                                // Event Context Banner
                                if (widget.isForEvent && widget.eventId != null)
                                  _buildEventContextBanner(),

                                if (widget.isForEvent && widget.eventId != null)
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
                                    'wishlists.wishlistDescriptionLabel',
                                  ),
                                  hint: localization.translate(
                                    'wishlists.wishlistDescriptionHint',
                                  ),
                                  prefixIcon: Icons.description_outlined,
                                  minLines: 2,
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

                                // Privacy Selection - Hide for guest users
                                if (!isGuest) ...[
                                  PrivacySelectionWidget(
                                    privacyOptions: _privacyOptions,
                                    selectedPrivacy: _selectedPrivacy,
                                    onPrivacySelected: (privacy) {
                                      setState(() {
                                        _selectedPrivacy = privacy;
                                      });
                                    },
                                    getPrivacyIcon:
                                        WishlistFormHelpers.getPrivacyIcon,
                                    getPrivacyTitle: (privacy) =>
                                        WishlistFormHelpers.getPrivacyTitle(
                                          privacy,
                                          localization,
                                        ),
                                    getPrivacyDescription: (privacy) =>
                                        WishlistFormHelpers.getPrivacyDescription(
                                          privacy,
                                          localization,
                                        ),
                                    getTitle: () => localization.translate(
                                      'wishlists.privacy',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Category Selection
                                CategorySelectionWidget(
                                  categoryOptions: _categoryOptions,
                                  selectedCategory: _selectedCategory,
                                  isCustomCategory: _isCustomCategory,
                                  customCategoryController:
                                      _customCategoryController,
                                  onCategorySelected: (category) {
                                    setState(() {
                                      if (_selectedCategory == category) {
                                        // Deselect if clicking the same category
                                        _selectedCategory = null;
                                        _isCustomCategory = false;
                                        _customCategoryController.clear();
                                      } else {
                                        // Select new category
                                        _selectedCategory = category;
                                        _isCustomCategory = category == 'custom';
                                        if (category != 'custom') {
                                          _customCategoryController.clear();
                                        }
                                      }
                                    });
                                    _validateForm();
                                  },
                                  getCategoryDisplayName: (category) =>
                                      WishlistFormHelpers.getCategoryDisplayName(
                                        category,
                                        localization,
                                      ),
                                  getTitle: () => localization.translate(
                                    'wishlists.category',
                                  ),
                                  customCategoryValidator: (value) {
                                    // Only validate if custom category is selected
                                    if (_selectedCategory == 'custom') {
                                      if (value?.isEmpty ?? true) {
                                        return 'Please enter a custom category name';
                                      }
                                      if (value != null && value.trim().length < 2) {
                                        return 'Category name must be at least 2 characters';
                                      }
                                      if (value != null && value.trim().length > 50) {
                                        return 'Category name must be less than 50 characters';
                                      }
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 40),

                                // Action Buttons
                                CreateWishlistActionButtonsWidget(
                                  isEditing: widget.wishlistId != null,
                                  isFormValid: _isFormValid,
                                  isLoading: _isLoading,
                                  onCreate: () => _createWishlist(localization),
                                  onCancel: () => Navigator.pop(context),
                                  getCreateButtonText: () =>
                                      widget.wishlistId != null
                                      ? 'Update Wishlist'
                                      : localization.translate(
                                          'wishlists.createWishlist',
                                        ),
                                ),

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

  /// Load wishlist data when editing
  Future<void> _loadWishlistData() async {
    if (widget.wishlistId == null) return;
    setState(() => _isLoading = true);
    try {
      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);
      Map<String, dynamic> wishlistData;

      if (authService.isGuest) {
        // Load from local storage for guests
        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );
        final wishlist = await guestDataRepo.getWishlistById(
          widget.wishlistId!,
        );
        if (wishlist == null) {
          throw Exception('Wishlist not found');
        }
        // Convert Wishlist model to Map format
        wishlistData = {
          'id': wishlist.id,
          'name': wishlist.name,
          'description': wishlist.description,
          'privacy': wishlist.visibility.toString().split('.').last,
          'category': wishlist.category, // Load category from model (can be null)
        };
      } else {
        // Load from API for authenticated users
        wishlistData = await _wishlistRepository.getWishlistById(
          widget.wishlistId!,
        );
      }
      // Populate form fields
      if (mounted) {
        final category = wishlistData['category']?.toString();
        setState(() {
          _nameController.text = wishlistData['name']?.toString() ?? '';
          _descriptionController.text =
              wishlistData['description']?.toString() ?? '';
          _selectedPrivacy = wishlistData['privacy']?.toString() ?? 'public';
          
          if (category == null || category.isEmpty) {
            // No category selected
            _selectedCategory = null;
            _isCustomCategory = false;
            _customCategoryController.clear();
          } else {
            final isPredefinedCategory =
                _categoryOptions.contains(category) && category != 'custom';
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
          }
          _isLoading = false;
        });
        // Validate form after loading data
        _validateForm();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load wishlist: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load wishlist. Please try again.');
      }
    }
  }

  Future<void> _createWishlist(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final isEditing = widget.wishlistId != null;
    // Calculate final category - can be null if no category selected
    String? finalCategory;
    if (_selectedCategory == 'custom') {
      final customCategoryText = _customCategoryController.text.trim();
      // Only set custom category if text is provided
      finalCategory = customCategoryText.isNotEmpty ? customCategoryText : null;
    } else {
      finalCategory = _selectedCategory; // Can be null
    }
    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await _handleUpdateWishlist(localization, finalCategory);
      } else {
        await _handleCreateWishlist(localization, finalCategory);
      }
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    }
  }

  Future<void> _handleUpdateWishlist(
    LocalizationService localization,
    String? finalCategory,
  ) async {
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);

    if (authService.isGuest) {
      // Update wishlist locally for guest
      await _handleUpdateGuestWishlist(finalCategory);
      return;
    }

    // Update wishlist via API for authenticated users
    final response = await _wishlistRepository.updateWishlist(
      wishlistId: widget.wishlistId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      privacy: _selectedPrivacy,
      category: finalCategory,
    );

    setState(() => _isLoading = false);

    if (response['success'] == true ||
        response['data'] != null ||
        response['wishlist'] != null) {
      if (mounted) {
        WishlistSuccessDialogHelper.showEditSuccessDialog(context);
      }
    } else {
      final errorMessage =
          response['message']?.toString() ??
          'Failed to update wishlist. Please try again.';
      if (mounted) {
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  /// Update wishlist locally for guest users
  Future<void> _handleUpdateGuestWishlist(String? finalCategory) async {
    try {
      final guestDataRepo = Provider.of<GuestDataRepository>(
        context,
        listen: false,
      );

      // Get existing wishlist
      final existingWishlist = await guestDataRepo.getWishlistById(
        widget.wishlistId!,
      );
      if (existingWishlist == null) {
        throw Exception('Wishlist not found');
      }

      // Update wishlist with new data
      // Note: Guest wishlists keep 'private' visibility (local-only)
      final updatedWishlist = existingWishlist.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: finalCategory, // Save category
        updatedAt: DateTime.now(),
      );

      await guestDataRepo.updateWishlist(updatedWishlist);

      setState(() => _isLoading = false);

      if (mounted) {
        WishlistSuccessDialogHelper.showEditSuccessDialog(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Failed to update wishlist: $e');
      }
    }
  }

  Future<void> _handleCreateWishlist(
    LocalizationService localization,
    String? finalCategory,
  ) async {
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);

    if (authService.isGuest) {
      // Create wishlist locally for guest
      await _handleCreateGuestWishlist(finalCategory);
      return;
    }

    // Create wishlist via API for authenticated users
    final response = await _wishlistRepository.createWishlist(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      privacy: _selectedPrivacy,
      category: finalCategory,
    );

    setState(() => _isLoading = false);

    if (response['success'] == true || response['data'] != null) {
      final wishlistId = _extractWishlistId(response);
      if (wishlistId == null || wishlistId.isEmpty) {
        if (mounted) {
          _showErrorSnackBar(
            'Wishlist created but could not get ID. Please refresh the wishlists page.',
          );
        }
        return;
      }

      // If creating for event, link wishlist to event automatically
      if (widget.isForEvent && widget.eventId != null) {
        try {
          await _eventRepository.linkWishlistToEvent(
            eventId: widget.eventId!,
            wishlistId: wishlistId,
          );

          if (mounted) {
            // Navigate back to events screen
            // Use a post-frame callback to ensure navigation is safe
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              // Pop current screen first
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              // Then check if we need to navigate to events screen
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!mounted) return;

                final currentRoute = ModalRoute.of(context)?.settings.name;
                if (currentRoute != AppRoutes.events) {
                  // Navigate to events screen
                  Navigator.pushReplacementNamed(context, AppRoutes.events);
                }

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Wishlist created and linked to event successfully',
                    ),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              });
            });
          }
          return;
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar(
              'Wishlist created but failed to link to event: ${e.toString()}',
            );
          }
          return;
        }
      }

      // Normal flow for regular wishlist creation
      if (mounted) {
        WishlistSuccessDialogHelper.showCreateSuccessDialog(
          context: context,
          localization: localization,
          wishlistId: wishlistId,
          wishlistName: _nameController.text,
          onResetForm: _resetForm,
        );
      }
    } else {
      final errorMessage =
          response['message']?.toString() ??
          'Failed to create wishlist. Please try again.';
      if (mounted) {
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  String? _extractWishlistId(Map<String, dynamic> response) {
    final wishlistData = response['data'] ?? response['wishlist'] ?? response;
    final wishlistId =
        wishlistData['id']?.toString() ??
        wishlistData['wishlistId']?.toString() ??
        wishlistData['_id']?.toString() ??
        response['id']?.toString() ??
        response['wishlistId']?.toString();
    return wishlistId;
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _customCategoryController.clear();
    setState(() {
      _selectedPrivacy = 'public';
      _selectedCategory = null; // No category selected by default
      _isCustomCategory = false;
    });
  }

  /// Show error message as a dialog with Lottie animation
  Future<void> _handleCreateGuestWishlist(String? finalCategory) async {
    try {
      final guestDataRepo = Provider.of<GuestDataRepository>(
        context,
        listen: false,
      );

      // Create Wishlist model
      // For guest users, use 'private' visibility as default (local-only data)
      // This helps identify guest wishlists during migration after signup
      final wishlist = Wishlist(
        id: '', // Will be generated by repository
        userId: 'guest',
        type: WishlistType.public,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        // Guest wishlists are always private (local-only)
        // This serves as an identifier for guest-created wishlists
        visibility: WishlistVisibility.private,
        category: finalCategory, // Save category
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to local storage
      final wishlistId = await guestDataRepo.createWishlist(wishlist);

      setState(() => _isLoading = false);

      if (mounted) {
        // Use the same success dialog helper as authenticated users
        final localization = Provider.of<LocalizationService>(context, listen: false);
        WishlistSuccessDialogHelper.showCreateSuccessDialog(
          context: context,
          localization: localization,
          wishlistId: wishlistId,
          wishlistName: _nameController.text.trim(),
          onResetForm: _resetForm,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('Failed to create wishlist: $e');
      }
    }
  }

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

  /// Load event name from API
  Future<void> _loadEventName() async {
    if (widget.eventId == null) return;

    try {
      final event = await _eventRepository.getEventById(widget.eventId!);
      if (mounted) {
        setState(() {
          _eventName = event.name;
        });
      }
    } catch (e) {

      // Continue without event name - banner will show generic message
    }
  }

  /// Builds event context banner widget
  Widget _buildEventContextBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventName != null
                      ? 'Creating wishlist for: $_eventName'
                      : 'Creating wishlist for this event',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This wishlist will be automatically linked to the event',
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
}
