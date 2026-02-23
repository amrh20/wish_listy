import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

class FilterOptions extends StatefulWidget {
  final String selectedSortOption;
  final String? selectedEventType;
  final Function(String) onSortChanged;
  final Function(String?) onEventTypeChanged;
  final VoidCallback onClearAll;
  final VoidCallback onApply;

  const FilterOptions({
    super.key,
    required this.selectedSortOption,
    required this.selectedEventType,
    required this.onSortChanged,
    required this.onEventTypeChanged,
    required this.onClearAll,
    required this.onApply,
  });

  @override
  State<FilterOptions> createState() => _FilterOptionsState();
}

class _FilterOptionsState extends State<FilterOptions> {
  late String _selectedSortOption;
  late String? _selectedEventType;

  @override
  void initState() {
    super.initState();
    _selectedSortOption = widget.selectedSortOption;
    _selectedEventType = widget.selectedEventType;
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    return Container(
      color: AppColors.surface, // White background
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              localization.translate('events.filterAndSort'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Sort Options
            _buildSortSection(localization),
            const SizedBox(height: 24),

            // Filter Options
            _buildFilterSection(localization),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: localization.translate('events.clearAll'),
                    onPressed: () {
                      setState(() {
                        _selectedSortOption = 'date_upcoming';
                        _selectedEventType = null;
                      });
                      widget.onSortChanged(_selectedSortOption);
                      widget.onEventTypeChanged(_selectedEventType);
                      widget.onClearAll();
                    },
                    variant: ButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: localization.translate('events.apply'),
                    onPressed: () {
                      widget.onSortChanged(_selectedSortOption);
                      widget.onEventTypeChanged(_selectedEventType);
                      widget.onApply();
                    },
                    variant: ButtonVariant.gradient,
                    gradientColors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('events.sortBy'),
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...['date_upcoming', 'date_latest', 'name_az'].map((option) {
          return RadioListTile<String>(
            title: Text(_getSortOptionLabel(option, localization)),
            value: option,
            groupValue: _selectedSortOption,
            onChanged: (value) {
              setState(() {
                _selectedSortOption = value!;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFilterSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('events.filterByEventType'),
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<String?>(
          title: Text(localization.translate('events.allTypes')),
          value: null,
          groupValue: _selectedEventType,
          onChanged: (value) {
            setState(() {
              _selectedEventType = value;
            });
          },
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        ...[
          'birthday',
          'wedding',
          'anniversary',
          'graduation',
          'houseWarming',
        ].map((type) {
          return RadioListTile<String?>(
            title: Text(_getEventTypeLabel(type, localization)),
            value: type,
            groupValue: _selectedEventType,
            onChanged: (value) {
              setState(() {
                _selectedEventType = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  String _getSortOptionLabel(String option, LocalizationService localization) {
    switch (option) {
      case 'date_upcoming':
        return localization.translate('events.dateUpcomingFirst');
      case 'date_latest':
        return localization.translate('events.dateLatestFirst');
      case 'name_az':
        return localization.translate('events.nameAZ');
      default:
        return option;
    }
  }

  String _getEventTypeLabel(String type, LocalizationService localization) {
    switch (type) {
      case 'birthday':
        return localization.translate('events.birthday');
      case 'wedding':
        return localization.translate('events.wedding');
      case 'anniversary':
        return localization.translate('events.anniversary');
      case 'graduation':
        return localization.translate('events.graduation');
      case 'houseWarming':
        return localization.translate('events.housewarming');
      default:
        return type;
    }
  }
}
