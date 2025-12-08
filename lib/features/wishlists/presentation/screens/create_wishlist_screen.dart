import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import '../widgets/create_wishlist_header_widget.dart';
import '../widgets/privacy_selection_widget.dart';
import '../widgets/category_selection_widget.dart';
import '../widgets/create_wishlist_action_buttons_widget.dart';
import '../widgets/wishlist_form_helpers.dart';
import '../widgets/wishlist_success_dialog_helper.dart';

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

    _initializeAnimations();
    // Add listeners to form fields
    _nameController.addListener(_validateForm);
    _customCategoryController.addListener(_validateForm);
    // Load wishlist data if editing
    if (widget.wishlistId != null) {
      _loadWishlistData();
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
                  CreateWishlistHeaderWidget(
                    isEditing: widget.wishlistId != null,
                    onBack: () => Navigator.pop(context),
                    getTitle: () => widget.wishlistId != null
                        ? 'Edit Wishlist'
                        : localization.translate('wishlists.createWishlist'),
                    getSubtitle: () => localization.translate(
                      'wishlists.wishlistDescriptionOptional',
                    ),
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

                                // Category Selection
                                CategorySelectionWidget(
                                  categoryOptions: _categoryOptions,
                                  selectedCategory: _selectedCategory,
                                  isCustomCategory: _isCustomCategory,
                                  customCategoryController:
                                      _customCategoryController,
                                  onCategorySelected: (category) {
                                    setState(() {
                                      _selectedCategory = category;
                                      _isCustomCategory = category == 'custom';
                                      if (category != 'custom') {
                                        _customCategoryController.clear();
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
                                    if (_isCustomCategory &&
                                        (value?.isEmpty ?? true)) {
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
      final wishlistData = await _wishlistRepository.getWishlistById(
        widget.wishlistId!,
      );
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
    String finalCategory,
  ) async {
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

  Future<void> _handleCreateWishlist(
    LocalizationService localization,
    String finalCategory,
  ) async {
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
      _selectedCategory = 'general';
      _isCustomCategory = false;
    });
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
}
