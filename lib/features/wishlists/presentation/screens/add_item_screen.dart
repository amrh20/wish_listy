import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

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
  bool _isNameEmpty = true; // Track if name field is empty
  String _selectedWishlist = '';
  String _selectedPriority = 'medium';
  String _selectedWhereToFind = 'online'; // 'online', 'physical', 'anywhere'
  List<String> _productLinks = [];

  final List<String> _priorities = ['low', 'medium', 'high'];
  List<Map<String, dynamic>> _wishlists = [];

  final WishlistRepository _wishlistRepository = WishlistRepository();

  // Editing state
  bool _isEditing = false;
  String? _editingItemId;
  bool _hasLoadedEditingData = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadWishlists();
    // Listen to name controller changes to enable/disable button
    _nameController.addListener(_onNameChanged);
    // Listen to link controller changes to update paste/clear button icon
    _linkController.addListener(() {
      setState(() {
        // Trigger rebuild to update button icon
      });
    });
  }

  void _onNameChanged() {
    final isEmpty = _nameController.text.trim().isEmpty;
    if (_isNameEmpty != isEmpty) {
      setState(() {
        _isNameEmpty = isEmpty;
      });
    }
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
          final itemId = args['itemId'] as String?;
          final isEditingArg = args['isEditing'] as bool?;
          if (wishlistId != null) {
            _selectedWishlist = wishlistId;
          }
          if (itemId != null) {
            _editingItemId = itemId;
          }
          if (isEditingArg == true) {
            _isEditing = true;
          }
        }
      }
    }

    // If we are in editing mode and have both wishlist and wish IDs, load wish data once
    if (_isEditing &&
        !_hasLoadedEditingData &&
        _selectedWishlist.isNotEmpty &&
        _editingItemId != null) {
      _hasLoadedEditingData = true;
      _loadItemForEditing();
    }
  }

  /// Load existing wish data for editing
  Future<void> _loadItemForEditing() async {
    setState(() {
      _isLoading = true;
    });

    try {

      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);
      Map<String, dynamic> itemData = {};

      if (authService.isGuest) {
        // Load from local storage for guests

        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );
        final items = await guestDataRepo.getWishlistItems(_selectedWishlist);

        // Find the specific item by ID
        final item = items.firstWhere(
          (item) => item.id == _editingItemId,
          orElse: () {

            throw Exception('Item not found in local storage');
          },
        );

        // Convert WishlistItem to Map format
        // Parse description to extract storeName, storeLocation, and notes if they were stored there
        String? description = item.description;
        String? storeName;
        String? storeLocation;
        String? notes;

        // Try to parse extra info from description (format: "description | storeName: value | storeLocation: value | notes: value")
        if (description != null && description.contains(' | ')) {
          final parts = description.split(' | ');
          final mainDescriptionParts = <String>[];

          for (final part in parts) {
            if (part.startsWith('storeName:')) {
              storeName = part.substring('storeName:'.length).trim();
            } else if (part.startsWith('storeLocation:')) {
              storeLocation = part.substring('storeLocation:'.length).trim();
            } else if (part.startsWith('notes:')) {
              notes = part.substring('notes:'.length).trim();
            } else {
              mainDescriptionParts.add(part);
            }
          }

          // Reconstruct description without the extra info
          description = mainDescriptionParts.isEmpty
              ? null
              : mainDescriptionParts.join(' | ');
        }

        itemData = {
          'id': item.id,
          'name': item.name,
          'description': description,
          'url': item.link,
          'link': item.link,
          'image_url': item.imageUrl,
          'priority': item.priority.toString().split('.').last,
          'status': item.status.toString().split('.').last,
          'storeName': storeName,
          'storeLocation': storeLocation,
          'notes': notes,
        };
      } else {
        // Load from API for authenticated users
        final List<Map<String, dynamic>> itemsData = await _wishlistRepository
            .getItemsForWishlist(_selectedWishlist);

        // Find the specific wish by ID
        final foundItem = itemsData.firstWhere((item) {
          final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
          return id == _editingItemId;
        }, orElse: () => <String, dynamic>{});
        itemData = foundItem;
      }

      if (itemData.isEmpty) {

        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Populate form fields from API data
      _nameController.text = itemData['name']?.toString() ?? '';
      _descriptionController.text = itemData['description']?.toString() ?? '';
      // Update button state based on loaded name
      setState(() {
        _isNameEmpty = _nameController.text.trim().isEmpty;
      });

      // Determine where to find section based on available fields
      final url = itemData['url']?.toString();
      final storeName = itemData['storeName']?.toString();
      final storeLocation = itemData['storeLocation']?.toString();
      final notes = itemData['notes']?.toString();

      if (url != null && url.isNotEmpty) {
        _selectedWhereToFind = 'online';
        _linkController.text = url;
        _productLinks = [];
      } else if ((storeName != null && storeName.isNotEmpty) ||
          (storeLocation != null && storeLocation.isNotEmpty)) {
        _selectedWhereToFind = 'physical';
        _storeNameController.text = storeName ?? '';
        _storeLocationController.text = storeLocation ?? '';
      } else if (notes != null && notes.isNotEmpty) {
        _selectedWhereToFind = 'anywhere';
        _brandKeywordsController.text = notes;
      }

      // Priority
      final priorityStr =
          itemData['priority']?.toString().toLowerCase() ?? 'medium';
      if (_priorities.contains(priorityStr)) {
        _selectedPriority = priorityStr;
      } else {
        _selectedPriority = 'medium';
      }

      // Ensure setState is called to update UI after loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load wish: ${e.message}',
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.toString().contains('Exception')
                        ? e.toString().replaceFirst('Exception: ', '')
                        : 'Failed to load item details. Please try again.',
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load wishlists from API or local storage
  Future<void> _loadWishlists() async {
    setState(() {
      _isLoadingWishlists = true;
    });

    try {
      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);
      List<Map<String, dynamic>> wishlistsData;

      if (authService.isGuest) {
        // Load from local storage for guests

        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );
        final wishlists = await guestDataRepo.getAllWishlists();

        // Convert Wishlist models to Map format for consistency
        wishlistsData = wishlists.map((wishlist) {
          return {
            'id': wishlist.id,
            '_id': wishlist.id,
            'name': wishlist.name,
            'description': wishlist.description,
            'privacy': wishlist.visibility.toString().split('.').last,
            'category': 'general',
          };
        }).toList();

      } else {
        // Load from API for authenticated users

        wishlistsData = await _wishlistRepository.getWishlists();

      }

      setState(() {
        _wishlists = wishlistsData;
        _isLoadingWishlists = false;

        // If no wishlist is selected yet and we have wishlists, select the first one
        if (_selectedWishlist.isEmpty && wishlistsData.isNotEmpty) {
          final firstWishlistId =
              wishlistsData.first['id']?.toString() ??
              wishlistsData.first['_id']?.toString() ??
              '';
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
            final firstWishlistId =
                wishlistsData.first['id']?.toString() ??
                wishlistsData.first['_id']?.toString() ??
                '';
            if (firstWishlistId.isNotEmpty) {
              _selectedWishlist = firstWishlistId;
            }
          }
        }
      });
    } on ApiException catch (e) {

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
    _nameController.removeListener(_onNameChanged);
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
                                                'wishlists.pleaseEnterWishName',
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
                                            'wishlists.wishDescriptionLabel',
                                          ),
                                          hint: localization.translate(
                                            'wishlists.wishDescriptionHint',
                                          ),
                                          prefixIcon:
                                              Icons.description_outlined,
                                          minLines: 3,
                                          maxLines: 5,
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? localization.translate('wishlists.editWishlistItem')
                      : localization.translate('wishlists.addNewWish'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEditing
                      ? localization.translate('wishlists.addSomethingSpecial')
                      : localization.translate('wishlists.addWishSubtitle'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                ),
              ],
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
                final wishlistId =
                    wishlistData['id']?.toString() ??
                    wishlistData['_id']?.toString() ??
                    '';
                final wishlistName =
                    wishlistData['name']?.toString() ?? 'Unnamed';
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
                      // Preserve user input - do not clear controllers
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
                      // Preserve user input - do not clear controllers
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
            // Dynamic button: Paste when empty, Clear when not empty
            IconButton(
              onPressed: () {
                if (_linkController.text.isEmpty) {
                  // Paste from clipboard
                  _pasteFromClipboard();
                } else {
                  // Clear the field
                  setState(() {
                    _linkController.clear();
                  });
                }
              },
              icon: Icon(
                _linkController.text.isEmpty
                    ? Icons.content_paste_rounded
                    : Icons.close_rounded,
                color: _linkController.text.isEmpty
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _linkController.text.isEmpty
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceVariant,
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
      text: _isEditing
          ? localization.translate('wishlists.saveItem')
          : localization.translate('wishlists.addToWishlist'),
      onPressed: _isNameEmpty || _isLoading
          ? null
          : () => _saveItem(localization),
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
    try {
      if (_wishlists.isEmpty || wishlistId.isEmpty) {
        return 'Unnamed Wishlist';
      }

      // Find wishlist in the loaded list
      final wishlist = _wishlists.firstWhere((w) {
        try {
          final id = w['id']?.toString() ?? w['_id']?.toString() ?? '';
          return id == wishlistId;
        } catch (e) {
          return false;
        }
      }, orElse: () => <String, dynamic>{});

      if (wishlist.isNotEmpty) {
        final name = wishlist['name']?.toString();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }

      return 'Unnamed Wishlist'; // Fallback if not found
    } catch (e) {

      return 'Unnamed Wishlist'; // Safe fallback
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
      // Prepare data based on "Where can this gift be found?" selection
      // IMPORTANT: Only read data from the currently active tab (_selectedWhereToFind)
      // This ensures we don't send mixed data from different tabs to the API
      String? url;
      String? storeName;
      String? storeLocation;
      String? notes;

      if (_selectedWhereToFind == 'online') {
        // Online Store: use URL
        if (_productLinks.isNotEmpty) {
          // Use the first product link as the URL
          url = _productLinks.first;
        } else if (_linkController.text.isNotEmpty) {
          // Use the link from the input field if no links were added yet
          url = _linkController.text.trim();
        }
      } else if (_selectedWhereToFind == 'physical') {
        // Physical Store: use storeName and storeLocation
        if (_storeNameController.text.trim().isNotEmpty) {
          storeName = _storeNameController.text.trim();
        }
        if (_storeLocationController.text.trim().isNotEmpty) {
          storeLocation = _storeLocationController.text.trim();
        }
      } else if (_selectedWhereToFind == 'anywhere') {
        // Anywhere: use notes
        if (_brandKeywordsController.text.trim().isNotEmpty) {
          notes = _brandKeywordsController.text.trim();
        }
      }

      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);

      if (authService.isGuest) {
        // Save to local storage for guests
        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );

        // Parse priority
        ItemPriority priority = ItemPriority.medium;
        switch (_selectedPriority) {
          case 'low':
            priority = ItemPriority.low;
            break;
          case 'high':
            priority = ItemPriority.high;
            break;
          case 'urgent':
            priority = ItemPriority.urgent;
            break;
          default:
            priority = ItemPriority.medium;
        }

        if (_isEditing && _editingItemId != null) {
          // Update existing item

          try {
            final existingItems = await guestDataRepo.getWishlistItems(
              _selectedWishlist,
            );

            final existingItem = existingItems.firstWhere(
              (item) => item.id == _editingItemId,
              orElse: () {

                throw Exception('Item not found in local storage');
              },
            );

            // Build description that includes storeName, storeLocation, and notes if needed
            // For guest users, we'll store additional info in description as JSON-like string
            String? finalDescription =
                _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim();

            // If we have storeName, storeLocation, or notes, append them to description
            // This is a workaround since WishlistItem model doesn't have these fields
            // In the future, we should extend the model to include them
            if (storeName != null || storeLocation != null || notes != null) {
              final extraInfo = <String, String?>{};
              if (storeName != null && storeName.isNotEmpty)
                extraInfo['storeName'] = storeName;
              if (storeLocation != null && storeLocation.isNotEmpty)
                extraInfo['storeLocation'] = storeLocation;
              if (notes != null && notes.isNotEmpty) extraInfo['notes'] = notes;

              // Append extra info to description (simple format for now)
              if (finalDescription == null || finalDescription.isEmpty) {
                finalDescription = extraInfo.entries
                    .where((e) => e.value != null && e.value!.isNotEmpty)
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' | ');
              } else {
                finalDescription =
                    '$finalDescription | ${extraInfo.entries.where((e) => e.value != null && e.value!.isNotEmpty).map((e) => '${e.key}: ${e.value}').join(' | ')}';
              }
            }

            // Ensure name is not empty
            final itemName = _nameController.text.trim();
            if (itemName.isEmpty) {
              throw Exception('Item name cannot be empty');
            }

            // Preserve existing item's status and createdAt
            final updatedItem = existingItem.copyWith(
              name: itemName,
              description: finalDescription,
              link: url,
              priority: priority,
              status: existingItem.status, // Preserve status
              createdAt: existingItem.createdAt, // Preserve createdAt
              updatedAt: DateTime.now(),
            );

            await guestDataRepo.updateWishlistItem(updatedItem);

          } catch (e) {

            rethrow; // Re-throw to be caught by outer catch block
          }
        } else {
          // Add new item
          // Build description that includes storeName, storeLocation, and notes if needed
          String? finalDescription = _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim();

          // If we have storeName, storeLocation, or notes, append them to description
          if (storeName != null || storeLocation != null || notes != null) {
            final extraInfo = <String, String?>{};
            if (storeName != null && storeName.isNotEmpty)
              extraInfo['storeName'] = storeName;
            if (storeLocation != null && storeLocation.isNotEmpty)
              extraInfo['storeLocation'] = storeLocation;
            if (notes != null && notes.isNotEmpty) extraInfo['notes'] = notes;

            // Append extra info to description
            if (finalDescription == null || finalDescription.isEmpty) {
              finalDescription = extraInfo.entries
                  .where((e) => e.value != null && e.value!.isNotEmpty)
                  .map((e) => '${e.key}: ${e.value}')
                  .join(' | ');
            } else {
              finalDescription =
                  '$finalDescription | ${extraInfo.entries.where((e) => e.value != null && e.value!.isNotEmpty).map((e) => '${e.key}: ${e.value}').join(' | ')}';
            }
          }

          final newItem = WishlistItem(
            id: '', // Will be generated by repository
            wishlistId: _selectedWishlist,
            name: _nameController.text.trim(),
            description: finalDescription,
            link: url,
            priority: priority,
            status: ItemStatus.desired,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await guestDataRepo.addWishlistItem(_selectedWishlist, newItem);

        }
      } else {
        // Save via API for authenticated users
        if (_isEditing && _editingItemId != null) {
          // Call API to update existing wish
          final updateResponse = await _wishlistRepository.updateItem(
            itemId: _editingItemId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            url: url,
            storeName: storeName,
            storeLocation: storeLocation,
            notes: notes,
            priority: _selectedPriority,
            wishlistId: _selectedWishlist,
          );

        } else {
          // Call API to add wish
          await _wishlistRepository.addItemToWishlist(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            url: url,
            storeName: storeName,
            storeLocation: storeLocation,
            notes: notes,
            priority: _selectedPriority,
            wishlistId: _selectedWishlist,
          );

        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        // Show success message - different behavior for edit vs add
        if (_isEditing) {
          _showEditSuccessMessage(localization);
        } else {
          _showSuccessMessage(localization);
        }
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
    } catch (e, stackTrace) {
      // Handle unexpected errors

      if (mounted) {
        setState(() => _isLoading = false);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.toString().contains('Exception')
                        ? e.toString().replaceFirst('Exception: ', '')
                        : 'Failed to save item. Please try again.',
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
    }
  }

  void _selectLocationFromMap() {
    // Mock location picker - show dialog with dummy locations
    final dummyLocations = [
      'Cairo Festival City',
      'Mall of Arabia',
      'City Stars Mall',
      'Nile City Towers',
    ];

    final TextEditingController customLocationController =
        TextEditingController();
    bool showCustomInput = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Select Location',
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!showCustomInput) ...[
                // Show location list
                ...dummyLocations.map((location) {
                  return ListTile(
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(location, style: AppStyles.bodyMedium),
                    onTap: () {
                      setState(() {
                        _storeLocationController.text = location;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
                // Other option
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: Text('Other', style: AppStyles.bodyMedium),
                  onTap: () {
                    setDialogState(() {
                      showCustomInput = true;
                    });
                  },
                ),
              ] else ...[
                // Show custom input field
                TextField(
                  controller: customLocationController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: Provider.of<LocalizationService>(context, listen: false).translate('wishlists.storeLocation'),
                    hintText: Provider.of<LocalizationService>(context, listen: false).translate('wishlists.enterStoreLocation'),
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  style: AppStyles.bodyMedium,
                ),
              ],
            ],
          ),
          actions: [
            if (showCustomInput) ...[
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    showCustomInput = false;
                    customLocationController.clear();
                  });
                },
                child: Text(
                  'Back',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final customLocation = customLocationController.text.trim();
                  if (customLocation.isNotEmpty) {
                    setState(() {
                      _storeLocationController.text = customLocation;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('app.add'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('app.cancel'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Paste URL from clipboard into link controller
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final url = clipboardData.text!.trim();
        if (_isValidUrl(url)) {
          setState(() {
            _linkController.text = url;
          });
        } else {
          // Show error if clipboard content is not a valid URL
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
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
        // Show error if clipboard is empty
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
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
              backgroundColor: AppColors.info,
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to read clipboard',
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
  }

  /// Show success message for adding wish (with dialog)
  void _showSuccessMessage(LocalizationService localization) {
    try {
      // Safely get wishlist name
      String wishlistName;
      try {
        wishlistName = _getWishlistDisplayName(_selectedWishlist, localization);
      } catch (e) {

        wishlistName = 'wishlist'; // Fallback name
      }

      ConfirmationDialog.show(
        context: context,
        isSuccess: true,
        title: localization.translate('wishlists.wishAdded'),
        message: localization.translate(
          'wishlists.wishAddedToWishlist',
          args: {
            'wishName': _nameController.text,
            'wishlistName': wishlistName,
          },
        ),
        primaryActionLabel: 'Done',
        onPrimaryAction: () {
          Navigator.of(context).pop();
        },
        secondaryActionLabel: localization.translate('wishlists.addAnother'),
        onSecondaryAction: () {
          _clearForm();
        },
      );
    } catch (e, stackTrace) {

      // If dialog fails, show a simple snackbar instead
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wish added successfully',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
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
        // Navigate back after showing snackbar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  /// Show success message for editing wish (with SnackBar and redirect)
  void _showEditSuccessMessage(LocalizationService localization) {
    // Show success SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localization.translate('messages.itemUpdated'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Navigate back to items screen after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close add wish screen
      }
    });
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
