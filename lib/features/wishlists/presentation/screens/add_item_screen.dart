import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class AddItemScreen extends StatefulWidget {
  final String? wishlistId;

  const AddItemScreen({super.key, this.wishlistId});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _storeLocationController = TextEditingController();
  final _brandKeywordsController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String _selectedWishlist = 'public';
  String _selectedPriority = 'medium';
  String? _selectedImagePath;
  String _selectedWhereToFind = 'online'; // 'online', 'physical', 'anywhere'
  List<String> _productLinks = [];

  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];
  final List<String> _wishlists = [
    'public',
    'birthday',
    'christmas',
    'anniversary',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    if (widget.wishlistId != null) {
      _selectedWishlist = widget.wishlistId!;
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _storeNameController.dispose();
    _storeLocationController.dispose();
    _brandKeywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: DecorativeBackground(
            showGifts: true,
            child: Stack(
              children: [
                // Animated Background
                AnimatedBackground(
                  colors: [
                    AppColors.background,
                    AppColors.accent.withOpacity(0.03),
                    AppColors.primary.withOpacity(0.02),
                  ],
                ),

                // Content
                SafeArea(
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(localization),

                      // Form
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Wishlist Selection
                                        _buildWishlistSelection(localization),
                                        const SizedBox(height: 24),

                                        // Wish Title
                                        CustomTextField(
                                          controller: _nameController,
                                          label: localization.translate(
                                            'wishlists.wishTitle',
                                          ),
                                          hint: localization.translate(
                                            'wishlists.whatDoYouWishFor',
                                          ),
                                          prefixIcon:
                                              Icons.card_giftcard_outlined,
                                          isRequired: true,
                                          validator: (value) {
                                            if (value?.isEmpty ?? true) {
                                              return localization.translate(
                                                'wishlists.pleaseEnterItemName',
                                              );
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
                                            'wishlists.addDetailsAboutItem',
                                          ),
                                          prefixIcon:
                                              Icons.description_outlined,
                                          maxLines: 3,
                                          validator: null,
                                        ),

                                        const SizedBox(height: 20),

                                        // Where to Find Section
                                        _buildWhereToFindSection(localization),

                                        const SizedBox(height: 24),

                                        // Priority Selection
                                        _buildPrioritySelection(localization),

                                        const SizedBox(height: 32),

                                        // Action Buttons
                                        _buildActionButtons(localization),

                                        const SizedBox(
                                          height: 100,
                                        ), // Bottom padding
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                  localization.translate('wishlists.addNewWish'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  localization.translate('wishlists.addSomethingSpecial'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Quick Action Button
          IconButton(
            onPressed: () => _scanBarcode(localization),
            icon: const Icon(Icons.qr_code_scanner_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent.withOpacity(0.1),
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistSelection(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('wishlists.addToWishlist'),
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
            children: _wishlists.map((wishlist) {
              final isSelected = _selectedWishlist == wishlist;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWishlist = wishlist;
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
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getWishlistDisplayName(wishlist, localization),
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

  Widget _buildPrioritySelection(LocalizationService localization) {
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
              Icon(Icons.flag_outlined, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('wishlists.selectPriority'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _priorities.map((priority) {
              final isSelected = _selectedPriority == priority;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                          size: 20,
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

  Widget _buildWhereToFindSection(LocalizationService localization) {
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
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('wishlists.whereToFind'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Where to Find Options
          Row(
            children: [
              Expanded(
                child: _buildWhereToFindOption(
                  icon: Icons.shopping_cart_outlined,
                  title: localization.translate('wishlists.onlineStore'),
                  isSelected: _selectedWhereToFind == 'online',
                  onTap: () {
                    setState(() {
                      _selectedWhereToFind = 'online';
                      _selectedImagePath = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWhereToFindOption(
                  icon: Icons.store_outlined,
                  title: localization.translate('wishlists.physicalStore'),
                  isSelected: _selectedWhereToFind == 'physical',
                  onTap: () {
                    setState(() {
                      _selectedWhereToFind = 'physical';
                      _productLinks.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildWhereToFindOption(
                  icon: Icons.help_outline,
                  title: localization.translate('wishlists.anywhere'),
                  isSelected: _selectedWhereToFind == 'anywhere',
                  onTap: () {
                    setState(() {
                      _selectedWhereToFind = 'anywhere';
                      _productLinks.clear();
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Conditional Content based on selection
          _buildConditionalContent(localization),
        ],
      ),
    );
  }

  Widget _buildWhereToFindOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppStyles.caption.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionalContent(LocalizationService localization) {
    switch (_selectedWhereToFind) {
      case 'online':
        return _buildOnlineStoreContent(localization);
      case 'physical':
        return _buildPhysicalStoreContent(localization);
      case 'anywhere':
        return _buildAnywhereContent(localization);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOnlineStoreContent(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Links
        Text(
          localization.translate('wishlists.productLinks'),
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Existing Links
        if (_productLinks.isNotEmpty) ...[
          ..._productLinks.asMap().entries.map((entry) {
            int index = entry.key;
            String link = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link,
                      style: AppStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _productLinks.removeAt(index);
                      });
                    },
                    icon: Icon(Icons.close, color: AppColors.error, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Add Link Field
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _linkController,
                label: localization.translate('wishlists.addProductLink'),
                hint: localization.translate('wishlists.enterProductUrl'),
                prefixIcon: Icons.link_outlined,
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!_isValidUrl(value)) {
                      return localization.translate(
                        'wishlists.pleaseEnterValidUrl',
                      );
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_linkController.text.isNotEmpty &&
                    _isValidUrl(_linkController.text)) {
                  setState(() {
                    _productLinks.add(_linkController.text);
                    _linkController.clear();
                  });
                }
              },
              icon: Icon(Icons.add, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Upload Image Option
        _buildImageUploadOption(
          icon: Icons.photo_library_outlined,
          label: localization.translate('wishlists.uploadImage'),
          onTap: _pickImageFromGallery,
        ),
      ],
    );
  }

  Widget _buildPhysicalStoreContent(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store Name
        CustomTextField(
          controller: _storeNameController,
          label: localization.translate('wishlists.storeName'),
          hint: localization.translate('wishlists.enterStoreName'),
          prefixIcon: Icons.store_outlined,
        ),
        const SizedBox(height: 16),

        // Store Location
        CustomTextField(
          controller: _storeLocationController,
          label: localization.translate('wishlists.storeLocation'),
          hint: localization.translate('wishlists.enterStoreLocation'),
          prefixIcon: Icons.location_on_outlined,
          suffixIcon: IconButton(
            icon: Icon(Icons.map_outlined),
            onPressed: _selectLocationFromMap,
          ),
        ),
        const SizedBox(height: 16),

        // Upload Image
        _buildImageUploadOption(
          icon: Icons.camera_alt_outlined,
          label: localization.translate('wishlists.takePhoto'),
          onTap: _pickImageFromGallery,
        ),
      ],
    );
  }

  Widget _buildAnywhereContent(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand or Keywords
        CustomTextField(
          controller: _brandKeywordsController,
          label: localization.translate('wishlists.brandOrKeywords'),
          hint: localization.translate('wishlists.enterBrandOrKeywords'),
          prefixIcon: Icons.tag_outlined,
        ),
        const SizedBox(height: 16),

        // Upload Image
        _buildImageUploadOption(
          icon: Icons.photo_library_outlined,
          label: localization.translate('wishlists.uploadImage'),
          onTap: _pickImageFromGallery,
        ),
      ],
    );
  }

  Widget _buildImageUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    if (_selectedImagePath != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surfaceVariant,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.image_outlined,
                size: 60,
                color: AppColors.textTertiary,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _selectedImagePath = null;
                  });
                },
                icon: Icon(Icons.close, color: AppColors.error),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.info, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(LocalizationService localization) {
    return CustomButton(
      text: localization.translate('wishlists.addToWishlist'),
      onPressed: () => _saveItem(localization),
      isLoading: _isLoading,
      variant: ButtonVariant.gradient,
      gradientColors: [AppColors.primary, AppColors.secondary],
    );
  }

  // Helper Methods
  String _getWishlistDisplayName(
    String wishlist,
    LocalizationService localization,
  ) {
    switch (wishlist) {
      case 'public':
        return localization.translate('wishlists.publicWishlist');
      case 'birthday':
        return localization.translate('wishlists.birthday2024');
      case 'christmas':
        return localization.translate('wishlists.christmas2024');
      case 'anniversary':
        return localization.translate('wishlists.anniversary');
      default:
        return wishlist;
    }
  }

  String _getPriorityDisplayName(
    String priority,
    LocalizationService localization,
  ) {
    switch (priority) {
      case 'low':
        return localization.translate('wishlists.low');
      case 'medium':
        return localization.translate('wishlists.medium');
      case 'high':
        return localization.translate('wishlists.high');
      case 'urgent':
        return localization.translate('wishlists.urgent');
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return AppColors.info;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.secondary;
      case 'urgent':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'low':
        return Icons.trending_down;
      case 'medium':
        return Icons.trending_flat;
      case 'high':
        return Icons.trending_up;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.flag_outlined;
    }
  }

  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  // Action Methods
  Future<void> _saveItem(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Show success message
    _showSuccessMessage(localization);
  }

  void _scanBarcode(LocalizationService localization) {
    // Barcode scanning functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localization.translate('wishlists.barcodeScannerComingSoon'),
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _pickImageFromGallery() {
    setState(() {
      _selectedImagePath = 'gallery_image.jpg';
    });
  }

  void _selectLocationFromMap() {
    // Mock implementation - in real app, open map picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Map picker coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showSuccessMessage(LocalizationService localization) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Text(
              localization.translate('wishlists.itemAdded'),
              style: AppStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localization.translate(
                'wishlists.itemAddedToWishlist',
                args: {
                  'itemName': _nameController.text,
                  'wishlistName': _getWishlistDisplayName(
                    _selectedWishlist,
                    localization,
                  ),
                },
              ),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: localization.translate('wishlists.addAnother'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _clearForm();
                    },
                    variant: ButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Done',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    variant: ButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _linkController.clear();
    setState(() {
      _selectedPriority = 'medium';
      _selectedImagePath = null;
      _selectedWhereToFind = 'online';
      _productLinks.clear();
    });
  }
}
