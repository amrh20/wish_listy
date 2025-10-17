import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/decorative_background.dart';
import '../../services/localization_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String _selectedGender = 'preferNotToSay';
  DateTime? _selectedBirthDate;

  final List<String> _genderOptions = [
    'male',
    'female',
    'other',
    'preferNotToSay',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
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

  void _loadUserData() {
    // Load existing user data
    _firstNameController.text = 'John';
    _lastNameController.text = 'Doe';
    _emailController.text = 'john.doe@example.com';
    _phoneController.text = '+1234567890';
    _bioController.text = 'Love giving and receiving thoughtful gifts!';
    _locationController.text = 'New York, USA';
    _selectedGender = 'male';
    _selectedBirthDate = DateTime(1990, 1, 15);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
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

                                // Profile Picture Section
                                _buildProfilePictureSection(localization),

                                const SizedBox(height: 32),

                                // Personal Information
                                _buildPersonalInfoSection(localization),

                                const SizedBox(height: 24),

                                // Contact Information
                                _buildContactInfoSection(localization),

                                const SizedBox(height: 24),

                                // Additional Information
                                _buildAdditionalInfoSection(localization),

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
                  localization.translate('profile.editProfile'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  localization.translate('profile.personalInfo'),
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

  Widget _buildProfilePictureSection(LocalizationService localization) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.person, size: 60, color: AppColors.primary),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _changeProfilePicture(localization),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localization.translate('profile.changeProfilePicture'),
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(LocalizationService localization) {
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
              Icon(Icons.person_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('profile.personalInfo'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // First Name & Last Name
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _firstNameController,
                  label: localization.translate('profile.firstName'),
                  prefixIcon: Icons.person,
                  isRequired: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return localization.translate('auth.pleaseEnterFullName');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _lastNameController,
                  label: localization.translate('profile.lastName'),
                  prefixIcon: Icons.person,
                  isRequired: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return localization.translate('auth.pleaseEnterFullName');
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Gender Selection
          _buildGenderSelection(localization),

          const SizedBox(height: 20),

          // Birth Date
          GestureDetector(
            onTap: () => _selectBirthDate(localization),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textTertiary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.translate('profile.birthDate'),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _selectedBirthDate != null
                              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                              : localization.translate('events.selectDate'),
                          style: AppStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(LocalizationService localization) {
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
                Icons.contact_mail_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Contact Information',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Email
          CustomTextField(
            controller: _emailController,
            label: localization.translate('auth.email'),
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return localization.translate('auth.pleaseEnterEmail');
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value!)) {
                return localization.translate('auth.pleaseEnterValidEmail');
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Phone
          CustomTextField(
            controller: _phoneController,
            label: localization.translate('auth.phone'),
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection(LocalizationService localization) {
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
              Icon(Icons.info_outline, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Additional Information',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bio
          CustomTextField(
            controller: _bioController,
            label: localization.translate('profile.bio'),
            hint: localization.translate('profile.bioPlaceholder'),
            prefixIcon: Icons.description,
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Location
          CustomTextField(
            controller: _locationController,
            label: localization.translate('profile.location'),
            hint: localization.translate('profile.locationPlaceholder'),
            prefixIcon: Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('auth.gender'),
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _genderOptions.map((gender) {
            final isSelected = _selectedGender == gender;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGender = gender;
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
                  _getGenderDisplayName(gender, localization),
                  style: AppStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
    );
  }

  Widget _buildActionButtons(LocalizationService localization) {
    return Column(
      children: [
        CustomButton(
          text: localization.translate('profile.saveChanges'),
          onPressed: () => _saveProfile(localization),
          isLoading: _isLoading,
          variant: ButtonVariant.gradient,
          gradientColors: [AppColors.primary, AppColors.secondary],
          icon: Icons.save,
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

  String _getGenderDisplayName(
    String gender,
    LocalizationService localization,
  ) {
    switch (gender) {
      case 'male':
        return localization.translate('auth.male');
      case 'female':
        return localization.translate('auth.female');
      case 'other':
        return localization.translate('auth.other');
      case 'preferNotToSay':
        return localization.translate('profile.preferNotToSay');
      default:
        return gender;
    }
  }

  void _selectBirthDate(LocalizationService localization) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }

  void _changeProfilePicture(LocalizationService localization) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: AppColors.primary),
                    title: Text(localization.translate('profile.takePhoto')),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement take photo
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.photo_library,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      localization.translate('profile.chooseFromGallery'),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement choose from gallery
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: Text(
                      localization.translate('profile.removeProfilePicture'),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement remove photo
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(localization.translate('profile.changesSaved')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    Navigator.pop(context);
  }
}

