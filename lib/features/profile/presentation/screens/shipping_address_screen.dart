import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _receiverNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _visibleToFriends = true;
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _receiverNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoadingData = true);
    try {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      final response = await authRepository.getCurrentUserProfile();
      if (!mounted) return;
      final data = response['data'] ?? response;
      final shipping = data['shippingAddress'] is Map
          ? data['shippingAddress'] as Map<String, dynamic>
          : null;

      // Pre-fill Receiver Name: use shippingAddress.receiverName if set; else user's fullName
      final receiverName = shipping?['receiverName']?.toString().trim();
      if (receiverName != null && receiverName.isNotEmpty) {
        _receiverNameController.text = receiverName;
      } else {
        final fullName = (data['fullName'] ?? data['name'])?.toString().trim() ?? '';
        if (fullName.isNotEmpty) _receiverNameController.text = fullName;
      }

      // Pre-fill Phone: use shippingAddress.phoneNumber if set; else user's registered phone
      final phoneNumber = shipping?['phoneNumber']?.toString().trim();
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        _phoneController.text = phoneNumber;
      } else {
        final phone = (data['phone'] ?? data['phoneNumber'] ?? data['username'])?.toString().trim() ?? '';
        if (phone.isNotEmpty) _phoneController.text = phone;
      }

      // Pre-fill Address from shippingAddress.fullAddress
      final fullAddress = shipping?['fullAddress']?.toString().trim();
      if (fullAddress != null && fullAddress.isNotEmpty) {
        _addressController.text = fullAddress;
      }

      // Pre-fill visibility: default true. Override only when API returns explicit value.
      final visible = shipping?['isVisibleToFriends'];
      if (visible != null) {
        _visibleToFriends = visible == true ||
            visible == 'true' ||
            visible == 1 ||
            visible == '1';
      }
    } catch (e) {
      if (mounted) {
        debugPrint('ShippingAddressScreen: Failed to load profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      final localization = Provider.of<LocalizationService>(context, listen: false);

      final profileData = <String, dynamic>{
        'shippingAddress': {
          'receiverName': _receiverNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'fullAddress': _addressController.text.trim(),
          'isVisibleToFriends': _visibleToFriends,
        },
      };

      await authRepository.updateProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('profile.shippingAddressSaved') ??
                  'Shipping address saved successfully',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('profile.failedToUpdateProfile') ??
                  'Failed to update. Please try again.',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    final isRTL = localization.isRTL;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(8),
            shape: const CircleBorder(),
          ),
        ),
        title: Text(
          localization.translate('profile.shippingAddress'),
          style: AppStyles.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _receiverNameController,
                              label: localization.translate('profile.shippingReceiverName') ?? 'Full Name',
                              hint: localization.translate('profile.shippingReceiverNameHint') ?? 'Enter receiver name',
                              prefixIcon: Icons.person_outline,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? (localization.translate('profile.shippingReceiverNameRequired') ?? 'Required')
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                localization.translate('profile.shippingReceiverNameHelper') ??
                                    'This name will appear on the delivery package',
                                style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _phoneController,
                              label: localization.translate('profile.shippingPhone') ?? 'Phone Number',
                              hint: localization.translate('profile.shippingPhoneHint') ?? 'e.g. +201012345678',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? (localization.translate('profile.shippingPhoneRequired') ?? 'Required')
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                localization.translate('profile.shippingPhoneHelper') ??
                                    'Courier will use this number for delivery coordination',
                                style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _addressController,
                              label: localization.translate('profile.shippingDetailedAddress') ?? 'Detailed Address',
                              hint: localization.translate('profile.shippingAddressHint') ??
                                  'Building, street, area, city...',
                              prefixIcon: Icons.location_on_outlined,
                              minLines: 3,
                              maxLines: 4,
                              validator: (v) => (v?.trim().isEmpty ?? true)
                                  ? (localization.translate('profile.shippingAddressRequired') ?? 'Required')
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                localization.translate('profile.shippingAddressHelper') ??
                                    'Include building, street, area, and city for accurate delivery',
                                style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.border.withOpacity(0.8),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textTertiary.withOpacity(0.1),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  switchTheme: SwitchThemeData(
                                    trackColor: MaterialStateProperty.resolveWith((states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return AppColors.primary;
                                      }
                                      return AppColors.textTertiary.withOpacity(0.4);
                                    }),
                                    thumbColor: MaterialStateProperty.resolveWith((states) {
                                      return states.contains(MaterialState.selected)
                                          ? Colors.white
                                          : AppColors.textSecondary;
                                    }),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    localization.translate('profile.shippingVisibleToFriends') ??
                                        'Visible to Friends',
                                    style: AppStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      localization.translate('profile.shippingVisibleToFriendsHelper') ??
                                          'Friends can see your address when reserving a gift',
                                      style: AppStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  trailing: Switch(
                                    value: _visibleToFriends,
                                    onChanged: (v) {
                                      setState(() => _visibleToFriends = v);
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            CustomButton(
                              text: localization.translate('profile.saveAddress') ?? 'Save Address',
                              onPressed: _isLoading ? null : _saveAddress,
                              isLoading: _isLoading,
                              icon: Icons.save_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}
