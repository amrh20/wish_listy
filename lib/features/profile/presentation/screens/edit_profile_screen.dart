import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

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
  final _countryController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  Country? _selectedCountry;

  final List<String> _genderOptions = [
    'male',
    'female',
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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      final response = await authRepository.getCurrentUserProfile();

      final data = response['data'] ?? response;

      if (mounted) {
        setState(() {
          _populateFields(data);
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('profile.failedToLoadProfile') ?? 'Failed to load profile data. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    // Handle fullName - split into firstName and lastName
    final fullName = data['fullName'] ?? data['name'] ?? '';
    if (fullName.isNotEmpty) {
      final nameParts = fullName.trim().split(' ');
      if (nameParts.length >= 2) {
        _firstNameController.text = nameParts.first;
        _lastNameController.text = nameParts.sublist(1).join(' ');
      } else {
        _firstNameController.text = fullName;
        _lastNameController.text = '';
      }
    }

    // Handle email
    final email = data['email'] ?? data['emailAddress'] ?? '';
    _emailController.text = email;

    // Handle phone (if available)
    final phone = data['phone'] ?? data['phoneNumber'] ?? '';
    _phoneController.text = phone;

    // Handle bio
    final bio = data['bio'] ?? data['biography'] ?? '';
    _bioController.text = bio;

    // Parse country - API returns 'country_code'
    if (data['country_code'] != null) {
      final countryCode = data['country_code'];
      try {
        _selectedCountry = Country.parse(countryCode.toString().toUpperCase());
        _countryController.text = _selectedCountry!.name;
      } catch (e) {
        _selectedCountry = null;
        _countryController.text = '';
      }
    } else if (data['countryCode'] != null || data['country'] != null) {
      final countryCode = data['countryCode'] ?? data['country'];
      try {
        _selectedCountry = Country.parse(countryCode.toString().toUpperCase());
        _countryController.text = _selectedCountry!.name;
      } catch (e) {
        _selectedCountry = null;
        _countryController.text = '';
      }
    } else {
      _selectedCountry = null;
      _countryController.text = '';
    }

    // Parse gender - API returns 'male' or 'female'
    if (data['gender'] != null) {
      final gender = data['gender'].toString().toLowerCase();
      _selectedGender = (gender == 'male' || gender == 'female') ? gender : null;
    } else {
      _selectedGender = null;
    }

    // Parse date of birth - API returns 'birth_date'
    if (data['birth_date'] != null) {
      final dateStr = data['birth_date'];
      if (dateStr is String) {
        try {
          _selectedBirthDate = DateTime.parse(dateStr);
        } catch (e) {
          _selectedBirthDate = null;
        }
      } else if (dateStr is DateTime) {
        _selectedBirthDate = dateStr;
      }
    } else if (data['dateOfBirth'] != null || data['birthDate'] != null) {
      final dateStr = data['dateOfBirth'] ?? data['birthDate'];
      if (dateStr is String) {
        try {
          _selectedBirthDate = DateTime.parse(dateStr);
        } catch (e) {
          _selectedBirthDate = null;
        }
      }
    } else {
      _selectedBirthDate = null;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _countryController.dispose();
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
                    child: _isLoadingData
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : FadeTransition(
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
            icon: const Icon(Icons.arrow_back_ios, size: 18),
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
                  if (_selectedBirthDate != null) ...[
                    // Edit icon only when date is already set
                    GestureDetector(
                      onTap: () => _enterDateManually(localization),
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                localization.translate('profile.contactInformation') ?? 'Contact Information',
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
            isRequired: false, // Email is optional when editing profile
            validator: (value) {
              // Email is optional - only validate format if provided
              if (value != null && value.trim().isNotEmpty) {
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return localization.translate('auth.pleaseEnterValidEmail');
                }
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\-\s]')),
            ],
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
                localization.translate('profile.additionalInformation') ?? 'Additional Information',
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

          // Country
          _buildCountryField(localization),
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

  Widget _buildCountryField(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.country') ?? 'Country',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCountryPicker(localization),
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
                _selectedCountry != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          _selectedCountry!.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      )
                    : Icon(
                        Icons.public_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountry != null
                        ? _selectedCountry!.name
                        : localization.translate('profile.selectCountry') ?? 'Select your country',
                    style: AppStyles.bodyMedium.copyWith(
                      color: _selectedCountry != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
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
    );
  }

  void _showCountryPicker(LocalizationService localization) {
    showCountryPicker(
      context: context,
      favorite: ['EG', 'SA', 'AE', 'US', 'GB'], // Favorite countries
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
          _countryController.text = country.name;
        });
      },
      countryListTheme: CountryListThemeData(
        flagSize: 28,
        backgroundColor: Colors.white,
        textStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        searchTextStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        inputDecoration: InputDecoration(
          labelText: localization.translate('profile.searchCountry') ?? 'Search',
          hintText: localization.translate('profile.searchCountry') ?? 'Search',
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
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
      default:
        return gender;
    }
  }

  // Normal date picker (calendar only - no switch to input)
  void _selectBirthDate(LocalizationService localization) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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

    if (date != null && mounted) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }

  // Manual date entry with auto-formatting
  void _enterDateManually(LocalizationService localization) async {
    final controller = TextEditingController();
    if (_selectedBirthDate != null) {
      final d = _selectedBirthDate!;
      controller.text =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    String? errorText;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(localization.translate('profile.selectDate') ?? 'Select date'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localization.translate('profile.enterDateDDMMYYYY') ?? 'Enter date (DD/MM/YYYY)',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      autofocus: true,
                      inputFormatters: [
                        _DateSlashFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        errorText: errorText,
                        errorMaxLines: 2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localization.translate('dialogs.cancel') ?? 'Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final raw = controller.text.replaceAll('/', '');
                    if (raw.length != 8) {
                      setDialogState(() {
                        errorText = localization.translate('profile.enterValidDate') ?? 'Enter a valid date (DD/MM/YYYY)';
                      });
                      return;
                    }
                    final day = int.tryParse(raw.substring(0, 2));
                    final month = int.tryParse(raw.substring(2, 4));
                    final year = int.tryParse(raw.substring(4, 8));
                    if (day == null || month == null || year == null ||
                        day < 1 || day > 31 || month < 1 || month > 12 ||
                        year < 1900) {
                      setDialogState(() {
                        errorText = localization.translate('profile.enterValidDate') ?? 'Enter a valid date (DD/MM/YYYY)';
                      });
                      return;
                    }
                    DateTime date;
                    try {
                      date = DateTime(year, month, day);
                      if (date.day != day || date.month != month) {
                        setDialogState(() {
                          errorText = localization.translate('profile.enterValidDate') ?? 'Enter a valid date (DD/MM/YYYY)';
                        });
                        return;
                      }
                    } catch (_) {
                      setDialogState(() {
                        errorText = localization.translate('profile.enterValidDate') ?? 'Enter a valid date (DD/MM/YYYY)';
                      });
                      return;
                    }
                    if (date.isAfter(DateTime.now())) {
                      setDialogState(() {
                        errorText = localization.translate('profile.dateCannotBeFuture') ?? 'Date cannot be in the future';
                      });
                      return;
                    }
                    Navigator.pop(context, date);
                  },
                  child: Text(localization.translate('dialogs.ok') ?? 'OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile(LocalizationService localization) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);

      // Prepare data for API - combine firstName and lastName into fullName
      final profileData = <String, dynamic>{
        'fullName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      // Add gender if selected
      if (_selectedGender != null) {
        profileData['gender'] = _selectedGender;
      }

      // Add date of birth if selected - API expects 'birth_date' in format YYYY-MM-DD
      if (_selectedBirthDate != null) {
        final year = _selectedBirthDate!.year;
        final month = _selectedBirthDate!.month.toString().padLeft(2, '0');
        final day = _selectedBirthDate!.day.toString().padLeft(2, '0');
        profileData['birth_date'] = '$year-$month-$day';
      }

      // Add country code if selected - API expects 'country_code'
      if (_selectedCountry != null) {
        profileData['country_code'] = _selectedCountry!.countryCode;
      }

      // Include phone in payload (API may use for profile/contact)
      profileData['phone'] = _phoneController.text.trim();

      // Call API to update profile
      await authRepository.updateProfile(profileData);

      if (mounted) {
        setState(() => _isLoading = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(localization.translate('profile.profileUpdatedSuccessfully') ?? 'Profile updated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        // Check if we can pop, otherwise navigate to main navigation
        if (Navigator.canPop(context)) {
          Navigator.pop(context, profileData);
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.mainNavigation,
            (route) => false,
          );
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? localization.translate('profile.failedToUpdateProfile') ?? 'Failed to update profile. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('profile.failedToUpdateProfile') ?? 'Failed to update profile. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}

/// Formats numeric input as DD/MM/YYYY with smart validation:
/// - Day: max 31, auto-pads with 0 (e.g. 4 → 04)
/// - Month: max 12, auto-pads with 0 (e.g. 9 → 09)
/// - Adds slashes automatically after day and month
/// - Handles backspace correctly (deletes through slashes)
class _DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // If deleting, just strip to raw digits and reformat simply
    if (newDigits.length < oldDigits.length) {
      // User is deleting - use simple formatting without smart padding
      if (newDigits.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      final buffer = StringBuffer();
      for (int i = 0; i < newDigits.length; i++) {
        if (i == 2 || i == 4) buffer.write('/');
        buffer.write(newDigits[i]);
      }
      final formatted = buffer.toString();
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Adding digits - apply smart validation
    String digits = newDigits;
    if (digits.length > 8) return oldValue;

    final buffer = StringBuffer();
    int i = 0;

    // === Day (positions 0-1) ===
    if (i < digits.length) {
      final d1 = int.parse(digits[i]);
      if (d1 > 3) {
        buffer.write('0');
        buffer.write(digits[i]);
        i++;
      } else if (d1 == 3 && i + 1 < digits.length) {
        final d2 = int.parse(digits[i + 1]);
        if (d2 > 1) {
          buffer.write('31');
          i += 2;
        } else {
          buffer.write(digits[i]);
          i++;
          buffer.write(digits[i]);
          i++;
        }
      } else if (d1 == 0 && i + 1 < digits.length && digits[i + 1] == '0') {
        buffer.write('01');
        i += 2;
      } else {
        buffer.write(digits[i]);
        i++;
        if (i < digits.length) {
          buffer.write(digits[i]);
          i++;
        }
      }
    }

    // Slash after day
    if (buffer.length == 2 && i <= digits.length) {
      buffer.write('/');
    }

    // === Month (positions 2-3) ===
    if (i < digits.length) {
      final m1 = int.parse(digits[i]);
      if (m1 > 1) {
        buffer.write('0');
        buffer.write(digits[i]);
        i++;
      } else if (m1 == 1 && i + 1 < digits.length) {
        final m2 = int.parse(digits[i + 1]);
        if (m2 > 2) {
          buffer.write('12');
          i += 2;
        } else {
          buffer.write(digits[i]);
          i++;
          buffer.write(digits[i]);
          i++;
        }
      } else if (m1 == 0 && i + 1 < digits.length && digits[i + 1] == '0') {
        buffer.write('01');
        i += 2;
      } else {
        buffer.write(digits[i]);
        i++;
        if (i < digits.length) {
          buffer.write(digits[i]);
          i++;
        }
      }
    }

    // Slash after month
    if (buffer.length == 5 && i <= digits.length) {
      buffer.write('/');
    }

    // === Year (positions 4-7) ===
    while (i < digits.length) {
      buffer.write(digits[i]);
      i++;
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

