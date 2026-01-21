import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        final isRTL = localization.isRTL;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
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
              localization.translate('profile.changePassword'),
              style: AppStyles.heading3.copyWith(
                color: AppColors.textPrimary,
                fontFamily: 'Alexandria',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Center(
                        child: Text(
                          localization.translate('profile.changePasswordInstruction'),
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'Alexandria',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Current Password Field
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: localization.translate('profile.currentPassword'),
                        hint: localization.translate('profile.enterCurrentPassword'),
                        obscureText: _obscureCurrentPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('profile.currentPasswordRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // New Password Field
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: localization.translate('profile.newPassword'),
                        hint: localization.translate('profile.enterNewPassword'),
                        obscureText: _obscureNewPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('profile.newPasswordRequired');
                          }
                          if (value.length < 6) {
                            return localization.translate('profile.passwordMinLength');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm New Password Field
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: localization.translate('profile.confirmNewPassword'),
                        hint: localization.translate('profile.enterConfirmPassword'),
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localization.translate('profile.confirmPasswordRequired');
                          }
                          if (value != _newPasswordController.text) {
                            return localization.translate('profile.passwordsDoNotMatch');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: localization.translate('profile.updatePassword'),
                          onPressed: _isLoading ? null : _changePassword,
                          variant: ButtonVariant.primary,
                          isLoading: _isLoading,
                        ),
                      ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontFamily: 'Alexandria',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontFamily: 'Alexandria',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              fontFamily: 'Alexandria',
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textTertiary,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final localization = Provider.of<LocalizationService>(context, listen: false);
    final authRepository = Provider.of<AuthRepository>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await authRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('profile.passwordChangedSuccess'),
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('profile.passwordChangeFailed'),
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
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
