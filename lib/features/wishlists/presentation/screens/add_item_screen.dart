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
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';

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
  bool _isLoadingWishlists = false;
  String _selectedWishlist = '';
  String _selectedPriority = 'medium';
  String _selectedWhereToFind = 'online'; // 'online', 'physical', 'anywhere'
  List<String> _productLinks = [];

  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];
  List<Map<String, dynamic>> _wishlists = [];

  final WishlistRepository _wishlistRepository = WishlistRepository();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadWishlists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get wishlistId from route arguments if not provided in constructor
    if (widget.wishlistId != null) {
      _selectedWishlist = widget.wishlistId!;
    } else {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        if (args is String) {
          // If argument is directly a string (wishlistId)
          _selectedWishlist = args;
        } else if (args is Map<String, dynamic>) {
          // If argument is a map with wishlistId
          final wishlistId = args['wishlistId'] as String?;
          if (wishlistId != null) {
            _selectedWishlist = wishlistId;
          }
        }
      }
    }
  }

  /// Load wishlists from API
  Future<void> _loadWishlists() async {
    setState(() {
      _isLoadingWishlists = true;
    });

    try {
      debugPrint('📡 AddItemScreen: Loading wishlists...');
      final wishlistsData = await _wishlistRepository.getWishlists();
      debugPrint('📡 AddItemScreen: Received ${wishlistsData.length} wishlists');

      setState(() {
        _wishlists = wishlistsData;
        _isLoadingWishlists = false;
        
        // If no wishlist is selected yet and we have wishlists, select the first one
        if (_selectedWishlist.isEmpty && wishlistsData.isNotEmpty) {
          final firstWishlistId = wishlistsData.first['id']?.toString() ?? 
                                  wishlistsData.first['_id']?.toString() ?? '';
          if (firstWishlistId.isNotEmpty) {
            _selectedWishlist = firstWishlistId;
          }
        }
        
        // Ensure the selected wishlist from route arguments is still valid
        if (_selectedWishlist.isNotEmpty) {
          final exists = wishlistsData.any((w) {
            final id = w['id']?.toString() ?? w['_id']?.toString() ?? '';
            return id == _selectedWishlist;
          });
          if (!exists && wishlistsData.isNotEmpty) {
            // If selected wishlist doesn't exist, select the first one
            final firstWishlistId = wishlistsData.first['id']?.toString() ?? 
                                    wishlistsData.first['_id']?.toString() ?? '';
            if (firstWishlistId.isNotEmpty) {
              _selectedWishlist = firstWishlistId;
            }
          }
        }
      });
    } on ApiException catch (e) {
      debugPrint('❌ AddItemScreen: Error loading wishlists: ${e.message}');
      setState(() {
        _isLoadingWishlists = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load wishlists: ${e.message}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ AddItemScreen: Unexpected error loading wishlists: $e');
      setState(() {
        _isLoadingWishlists = false;
      });
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
          if (_isLoadingWishlists)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_wishlists.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No wishlists found. Please create a wishlist first.',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _wishlists.map((wishlistData) {
                final wishlistId = wishlistData['id']?.toString() ?? 
                                   wishlistData['_id']?.toString() ?? '';
                final wishlistName = wishlistData['name']?.toString() ?? 'Unnamed';
                final isSelected = _selectedWishlist == wishlistId;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedWishlist = wishlistId;
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
                      wishlistName,
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
      ],
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
    String wishlistId,
    LocalizationService localization,
  ) {
    // Find wishlist in the loaded list
    final wishlist = _wishlists.firstWhere(
      (w) {
        final id = w['id']?.toString() ?? w['_id']?.toString() ?? '';
        return id == wishlistId;
      },
      orElse: () => <String, dynamic>{},
    );
    
    if (wishlist.isNotEmpty) {
      return wishlist['name']?.toString() ?? 'Unnamed Wishlist';
    }
    
    return wishlistId; // Fallback to ID if not found
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

    // Validate wishlistId
    if (_selectedWishlist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please select a wishlist',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            top: 60,
            left: 16,
            right: 16,
            bottom: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get URL from product links if online store is selected
      String? url;
      if (_selectedWhereToFind == 'online' && _productLinks.isNotEmpty) {
        // Use the first product link as the URL
        url = _productLinks.first;
      } else if (_selectedWhereToFind == 'online' && _linkController.text.isNotEmpty) {
        // Use the link from the input field if no links were added yet
        url = _linkController.text.trim();
      }

      debugPrint('📤 AddItemScreen: Adding item to wishlist');
      debugPrint('   Name: ${_nameController.text}');
      debugPrint('   Description: ${_descriptionController.text}');
      debugPrint('   URL: $url');
      debugPrint('   Priority: $_selectedPriority');
      debugPrint('   WishlistId: $_selectedWishlist');

      // Call API to add item
      await _wishlistRepository.addItemToWishlist(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        url: url,
        priority: _selectedPriority,
        wishlistId: _selectedWishlist,
      );

      debugPrint('✅ AddItemScreen: Item added successfully');

      if (mounted) {
        setState(() => _isLoading = false);
        // Show success message
        _showSuccessMessage(localization);
      }
    } on ApiException catch (e) {
      // Handle API-specific errors
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.message,
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
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
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
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      debugPrint('Add item error: $e');
    }
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
        backgroundColor: Colors.white,
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
      _selectedWhereToFind = 'online';
      _productLinks.clear();
    });
  }
}
