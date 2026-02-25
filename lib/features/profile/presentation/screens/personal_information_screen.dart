import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

class PersonalInformationScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const PersonalInformationScreen({super.key, this.userData});

  @override
  _PersonalInformationScreenState createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _countryController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _selectedGender; // 'male' or 'female'
  DateTime? _selectedDateOfBirth;
  Country? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _bioController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _countryController = TextEditingController();

    // Always fetch fresh data from API when opening the screen
    _loadProfileData();
  }

  void _populateFields(Map<String, dynamic> data) {
    // Debug: Print received data
    
    // Handle name field - API returns 'fullName', but also support 'name' for backward compatibility
    final name = data['fullName'] ?? data['name'] ?? '';
    _nameController.text = name;
    
    // Handle email
    final email = data['email'] ?? data['emailAddress'] ?? '';
    _emailController.text = email;
    
    // Handle bio
    final bio = data['bio'] ?? data['biography'] ?? '';
    _bioController.text = bio;

    // Parse gender - API returns 'male' or 'female'
    if (data['gender'] != null) {
      final gender = data['gender'].toString().toLowerCase();
      _selectedGender = (gender == 'male' || gender == 'female') ? gender : null;
    } else {
      _selectedGender = null;
    }

    // Parse date of birth - API returns 'birth_date', but also support other formats
    if (data['birth_date'] != null) {
      final dateStr = data['birth_date'];
      if (dateStr is String) {
        try {
          _selectedDateOfBirth = DateTime.parse(dateStr);
          _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!);
        } catch (e) {
          // Invalid date format
          _selectedDateOfBirth = null;
          _dateOfBirthController.text = '';
        }
      } else if (dateStr is DateTime) {
        _selectedDateOfBirth = dateStr;
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!);
      }
    } else if (data['dateOfBirth'] != null || data['birthDate'] != null) {
      // Fallback to other field names for backward compatibility
      final dateStr = data['dateOfBirth'] ?? data['birthDate'];
      if (dateStr is String) {
        try {
          _selectedDateOfBirth = DateTime.parse(dateStr);
          _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!);
        } catch (e) {
          _selectedDateOfBirth = null;
          _dateOfBirthController.text = '';
        }
      } else if (dateStr is DateTime) {
        _selectedDateOfBirth = dateStr;
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!);
      }
    } else {
      _selectedDateOfBirth = null;
      _dateOfBirthController.text = '';
    }

    // Parse country - API returns 'country_code', but also support 'countryCode' for backward compatibility
    if (data['country_code'] != null) {
      final countryCode = data['country_code'];
      try {
        _selectedCountry = Country.parse(countryCode.toString().toUpperCase());
        _countryController.text = _selectedCountry!.name;
      } catch (e) {
        // Invalid country code
        _selectedCountry = null;
        _countryController.text = '';
      }
    } else if (data['countryCode'] != null || data['country'] != null) {
      // Fallback to other field names for backward compatibility
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
    
  }

  Future<void> _loadProfileData() async {
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
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _dateOfBirthController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localization.translate('profile.personalInformation')),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: SafeArea(
              child: _isLoadingData
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture Section
                            _buildProfilePictureSection(localization),
                            const SizedBox(height: 32),

                            // Form Fields
                            _buildFormFields(localization),
                            const SizedBox(height: 32),

                            // Save Button
                            _buildSaveButton(localization),
                            const SizedBox(height: 20), // Extra padding at bottom
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePictureSection(LocalizationService localization) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0].toUpperCase()
                        : 'A',
                    style: AppStyles.headingLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _nameController,
          label: localization.translate('profile.fullName') ?? 'Full Name',
          hint: localization.translate('profile.enterFullName') ?? 'Enter your full name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localization.translate('profile.nameRequired') ?? 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _emailController,
          label: localization.translate('profile.emailAddress') ?? 'Email Address',
          hint: localization.translate('profile.enterEmailAddress') ?? 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            // Email is optional - only validate format if provided
            if (value != null && value.trim().isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return localization.translate('profile.enterValidEmail') ?? 'Please enter a valid email';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Gender Selection
        _buildGenderSelector(localization),
        const SizedBox(height: 20),

        // Date of Birth
        _buildDateOfBirthField(localization),
        const SizedBox(height: 20),

        // Country Picker
        _buildCountryField(localization),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _bioController,
          label: localization.translate('profile.bio') ?? 'Bio',
          hint: localization.translate('profile.tellUsAboutYourself') ?? 'Tell us about yourself...',
          icon: Icons.info_outline,
          maxLines: 4,
          maxLength: 150,
        ),
      ],
    );
  }

  Widget _buildGenderSelector(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.gender') ?? 'Gender',
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildGenderButton(
                    label: localization.translate('profile.male') ?? 'Male',
                    value: 'male',
                    isSelected: _selectedGender == 'male',
                    onTap: () {
                      setState(() {
                        _selectedGender = 'male';
                      });
                    },
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.surfaceVariant),
                Expanded(
                  child: _buildGenderButton(
                    label: localization.translate('profile.female') ?? 'Female',
                    value: 'female',
                    isSelected: _selectedGender == 'female',
                    onTap: () {
                      setState(() {
                        _selectedGender = 'female';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderButton({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthField(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.dateOfBirth') ?? 'Date of Birth',
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextFormField(
            controller: _dateOfBirthController,
            readOnly: true,
            onTap: () => _selectDateOfBirth(localization),
            decoration: InputDecoration(
              hintText: localization.translate('profile.selectDateOfBirth') ?? 'DD/MM/YYYY',
              hintStyle: AppStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateOfBirth(LocalizationService localization) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 120);
    final lastDate = DateTime(now.year - 5); // Minimum age: 5 years

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: localization.translate('profile.selectDateOfBirth') ?? 'Select Date of Birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Widget _buildCountryField(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.country') ?? 'Country',
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextFormField(
            controller: _countryController,
            readOnly: true,
            onTap: () => _showCountryPicker(localization),
            decoration: InputDecoration(
              hintText: localization.translate('profile.selectCountry') ?? 'Select your country',
              hintStyle: AppStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: _selectedCountry != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        _selectedCountry!.flagEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    )
                  : Icon(Icons.public_outlined, color: AppColors.primary),
              suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
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
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            maxLength: maxLength,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: Icon(icon, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(LocalizationService localization) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: localization.translate('app.saveChanges') ?? 'Save Changes',
        onPressed: _isLoading ? null : _saveChanges,
        variant: ButtonVariant.primary,
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      final localization = Provider.of<LocalizationService>(context, listen: false);

      // Prepare data for API - Use API field names: birth_date, country_code, fullName
      final profileData = <String, dynamic>{
        'fullName': _nameController.text.trim(), // API expects 'fullName' not 'name'
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      // Add gender if selected
      if (_selectedGender != null) {
        profileData['gender'] = _selectedGender;
      }

      // Add date of birth if selected - API expects 'birth_date'
      if (_selectedDateOfBirth != null) {
        profileData['birth_date'] = _selectedDateOfBirth!.toIso8601String();
      } else {
      }

      // Add country code if selected - API expects 'country_code'
      if (_selectedCountry != null) {
        profileData['country_code'] = _selectedCountry!.countryCode;
      } else {
      }
      

      // Call API to update profile
      await authRepository.updateProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('profile.profileUpdatedSuccessfully') ?? 'Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, profileData);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('profile.failedToUpdateProfile') ?? 'Failed to update profile. Please try again.'),
            backgroundColor: AppColors.error,
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
}
