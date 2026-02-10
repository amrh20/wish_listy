import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/index.dart';

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
  final _customCategoryController = TextEditingController();

  // Item section controllers
  final _itemNameController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _itemUrlController = TextEditingController();
  final _itemStoreNameController = TextEditingController();
  final _itemStoreLocationController = TextEditingController();
  final _itemNotesController = TextEditingController();

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

  // Item section state
  String _itemSelectedWhereToFind = 'online'; // 'online', 'physical', 'anywhere'
  String _itemSelectedPriority = 'medium'; // 'low', 'medium', 'high'

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
  final List<String> _priorities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    // Add listeners to form fields
    _nameController.addListener(_validateForm);
    _customCategoryController.addListener(_validateForm);
    // Add listeners to item fields for validation
    _itemNameController.addListener(_validateForm);
    _itemDescriptionController.addListener(_validateForm);
    _itemUrlController.addListener(_validateForm);
    _itemStoreNameController.addListener(_validateForm);
    _itemStoreLocationController.addListener(_validateForm);
    _itemNotesController.addListener(_validateForm);
    // Initial validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
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

  /// Check if any item field is filled
  bool _hasAnyItemFieldFilled() {
    return _itemNameController.text.trim().isNotEmpty ||
         _itemDescriptionController.text.trim().isNotEmpty ||
         _itemUrlController.text.trim().isNotEmpty ||
         _itemStoreNameController.text.trim().isNotEmpty ||
         _itemStoreLocationController.text.trim().isNotEmpty ||
         _itemNotesController.text.trim().isNotEmpty;
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

    // Item validation: if any field filled, name is required
    final hasAnyItemField = _hasAnyItemFieldFilled();
    final itemNameValid = !hasAnyItemField ||
         (_itemNameController.text.trim().isNotEmpty);

    final isValid = isNameValid && isCustomCategoryValid && itemNameValid;

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
    _itemNameController.removeListener(_validateForm);
    _itemDescriptionController.removeListener(_validateForm);
    _itemUrlController.removeListener(_validateForm);
    _itemStoreNameController.removeListener(_validateForm);
    _itemStoreLocationController.removeListener(_validateForm);
    _itemNotesController.removeListener(_validateForm);
    _nameController.dispose();
    _customCategoryController.dispose();
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _itemUrlController.dispose();
    _itemStoreNameController.dispose();
    _itemStoreLocationController.dispose();
    _itemNotesController.dispose();
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
                        ? localization.translate('wishlists.editWishlist')
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
                                  CreateWishlistEventBannerWidget(
                                    eventName: _eventName,
                                    eventId: widget.eventId,
                                  ),

                                if (widget.isForEvent && widget.eventId != null)
                                  const SizedBox(height: 20),

                                // Wishlist Name
                                CustomTextField(
                                  controller: _nameController,
                                  label: localization.translate(
                                    'wishlists.wishlistName',
                                  ),
                                  hint: localization.translate(
                                    'wishlists.wishlistNameHint',
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

                                const SizedBox(height: 24),

                                // Add Item Section (Optional)
                                _buildAddItemSection(localization),

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
                                      ? localization.translate('wishlists.updateWishlist') ?? localization.translate('wishlists.editWishlist')
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
        final localization = Provider.of<LocalizationService>(context, listen: false);
        final errorMsg = e.message ?? localization.translate('wishlists.failedToLoadWishlist') ?? 'Failed to load wishlist. Please try again.';
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final localization = Provider.of<LocalizationService>(context, listen: false);
        _showErrorSnackBar(localization.translate('wishlists.failedToLoadWishlist') ?? 'Failed to load wishlist. Please try again.');
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

    // Build items array if any item fields are filled
    final items = _buildItemsArray();

    // Create wishlist via API for authenticated users
    final response = await _wishlistRepository.createWishlist(
      name: _nameController.text.trim(),
      privacy: _selectedPrivacy,
      category: finalCategory,
      items: items,
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
    _customCategoryController.clear();
    _itemNameController.clear();
    _itemDescriptionController.clear();
    _itemUrlController.clear();
    _itemStoreNameController.clear();
    _itemStoreLocationController.clear();
    _itemNotesController.clear();
    setState(() {
      _selectedPrivacy = 'public';
      _selectedCategory = null; // No category selected by default
      _isCustomCategory = false;
      _itemSelectedWhereToFind = 'online';
      _itemSelectedPriority = 'medium';
    });
    _validateForm();
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    ConfirmationDialog.show(
      context: context,
      isSuccess: false,
      title: localization.translate('wishlists.failedToCreateWishlist') ?? 'Failed to Create Wishlist',
      message: message,
      primaryActionLabel: localization.translate('common.tryAgain'),
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

  /// Build Add Item Section
  Widget _buildAddItemSection(LocalizationService localization) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  localization.translate('wishlists.addYourFirstItem') ?? 'Add your first item',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Optional)',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Item Name
            CustomTextField(
              controller: _itemNameController,
              label: localization.translate('wishlists.wishTitle') ?? 'Item Name',
              hint: localization.translate('wishlists.itemNameHint') ?? 'e.g., Nike Air Jordan',
              prefixIcon: Icons.card_giftcard_outlined,
              validator: (value) {
                if (_hasAnyItemFieldFilled()) {
                  if (value?.isEmpty ?? true) {
                    return localization.translate('wishlists.pleaseEnterWishName') ?? 
                           'Please enter item name';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Item Description
            CustomTextField(
              controller: _itemDescriptionController,
              label: localization.translate('wishlists.wishDescriptionLabel') ?? 'Description',
              hint: localization.translate('wishlists.wishDescriptionHint') ?? 'Add details about this item',
              prefixIcon: Icons.description_outlined,
              minLines: 2,
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // Where to Find Section
            _buildItemWhereToFindSection(localization),

            const SizedBox(height: 20),

            // Priority Selection
            _buildItemPrioritySelection(localization),
          ],
        ),
      ),
    );
  }

  /// Build Where to Find Section for Item
  Widget _buildItemWhereToFindSection(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('wishlists.whereToFind') ?? 'Where to Find',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Where to Find Options
          Row(
            children: [
              Expanded(
                child: _buildItemWhereToFindOption(
                  icon: Icons.shopping_cart_outlined,
                  title: localization.translate('wishlists.onlineStore') ?? 'Online',
                  isSelected: _itemSelectedWhereToFind == 'online',
                  onTap: () {
                    setState(() {
                      _itemSelectedWhereToFind = 'online';
                    });
                    _validateForm();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildItemWhereToFindOption(
                  icon: Icons.store_outlined,
                  title: localization.translate('wishlists.physicalStore') ?? 'Store',
                  isSelected: _itemSelectedWhereToFind == 'physical',
                  onTap: () {
                    setState(() {
                      _itemSelectedWhereToFind = 'physical';
                    });
                    _validateForm();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildItemWhereToFindOption(
                  icon: Icons.help_outline,
                  title: localization.translate('wishlists.anywhere') ?? 'Anywhere',
                  isSelected: _itemSelectedWhereToFind == 'anywhere',
                  onTap: () {
                    setState(() {
                      _itemSelectedWhereToFind = 'anywhere';
                    });
                    _validateForm();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Conditional Content based on selection
          _buildItemConditionalContent(localization),
        ],
      ),
    );
  }

  /// Build Where to Find Option
  Widget _buildItemWhereToFindOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
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
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build Conditional Content based on Where to Find selection
  Widget _buildItemConditionalContent(LocalizationService localization) {
    switch (_itemSelectedWhereToFind) {
      case 'online':
        return _buildItemOnlineContent(localization);
      case 'physical':
        return _buildItemPhysicalContent(localization);
      case 'anywhere':
        return _buildItemAnywhereContent(localization);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Build Online Store Content
  Widget _buildItemOnlineContent(LocalizationService localization) {
    return CustomTextField(
      controller: _itemUrlController,
      label: localization.translate('wishlists.addProductLink') ?? 'Product URL',
      hint: localization.translate('wishlists.enterProductUrl') ?? 'Enter product URL',
      prefixIcon: Icons.link_outlined,
      keyboardType: TextInputType.url,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!_isValidUrl(value)) {
            return localization.translate('wishlists.pleaseEnterValidUrl') ??
                'Please enter a valid URL';
          }
        }
        return null;
      },
    );
  }

  /// Build Physical Store Content
  Widget _buildItemPhysicalContent(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _itemStoreNameController,
          label: localization.translate('wishlists.storeName') ?? 'Store Name',
          hint: localization.translate('wishlists.enterStoreName') ?? 'Enter store name',
          prefixIcon: Icons.store_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _itemStoreLocationController,
          label: localization.translate('wishlists.storeLocation') ?? 'Store Location',
          hint: localization.translate('wishlists.enterStoreLocation') ?? 'Enter store location',
          prefixIcon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  /// Build Anywhere Content
  Widget _buildItemAnywhereContent(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _itemNotesController,
          label: localization.translate('wishlists.brandOrKeywords') ?? 'Brand or Keywords',
          hint: localization.translate('wishlists.enterBrandOrKeywords') ?? 'Enter brand or keywords',
          prefixIcon: Icons.tag_outlined,
        ),
      ],
    );
  }

  /// Build Priority Selection for Item
  Widget _buildItemPrioritySelection(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                localization.translate('wishlists.selectPriority') ?? 'Priority',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _priorities.map((priority) {
              final isSelected = _itemSelectedPriority == priority;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _itemSelectedPriority = priority;
                    });
                    _validateForm();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getPriorityColor(priority).withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _getPriorityColor(priority)
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getPriorityIcon(priority),
                          color: isSelected
                              ? _getPriorityColor(priority)
                              : AppColors.textTertiary,
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPriorityDisplayName(priority, localization),
                          style: AppStyles.caption.copyWith(
                            color: isSelected
                                ? _getPriorityColor(priority)
                                : AppColors.textTertiary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 11,
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

  /// Get Priority Color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  /// Get Priority Icon
  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'low':
        return Icons.trending_down;
      case 'medium':
        return Icons.trending_flat;
      case 'high':
        return Icons.trending_up;
      default:
        return Icons.flag_outlined;
    }
  }

  /// Get Priority Display Name
  String _getPriorityDisplayName(String priority, LocalizationService localization) {
    switch (priority) {
      case 'low':
        return localization.translate('wishlists.priorityLow') ?? 'Low';
      case 'medium':
        return localization.translate('wishlists.priorityMedium') ?? 'Medium';
      case 'high':
        return localization.translate('wishlists.priorityHigh') ?? 'High';
      default:
        return priority;
    }
  }

  /// Validate URL
  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  /// Paste URL from clipboard
  Future<void> _pasteItemUrlFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final url = clipboardData.text!.trim();
        if (_isValidUrl(url)) {
          setState(() {
            _itemUrlController.text = url;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Clipboard does not contain a valid URL',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Clipboard is empty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to paste from clipboard: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Build Items Array for API
  List<Map<String, dynamic>>? _buildItemsArray() {
    if (!_hasAnyItemFieldFilled()) {
      return null; // Don't include items key
    }

    // Validate item name is provided
    final itemName = _itemNameController.text.trim();
    if (itemName.isEmpty) {
      return null; // Validation should prevent this, but safety check
    }

    final item = <String, dynamic>{
      'name': itemName,
      'priority': _itemSelectedPriority,
    };

    // Add optional fields
    final description = _itemDescriptionController.text.trim();
    if (description.isNotEmpty) {
      item['description'] = description;
    }

    // Add fields based on "Where to Find" selection
    if (_itemSelectedWhereToFind == 'online') {
      final url = _itemUrlController.text.trim();
      if (url.isNotEmpty) {
        item['url'] = url;
      }
    } else if (_itemSelectedWhereToFind == 'physical') {
      final storeName = _itemStoreNameController.text.trim();
      if (storeName.isNotEmpty) {
        item['storeName'] = storeName;
      }
      final storeLocation = _itemStoreLocationController.text.trim();
      if (storeLocation.isNotEmpty) {
        item['storeLocation'] = storeLocation;
      }
    } else if (_itemSelectedWhereToFind == 'anywhere') {
      final notes = _itemNotesController.text.trim();
      if (notes.isNotEmpty) {
        item['notes'] = notes;
      }
    }

    return [item]; // Return array with single item
  }

}
