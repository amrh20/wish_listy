import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import 'event_card.dart';

class CalendarView extends StatefulWidget {
  final List<EventSummary> events;
  final LocalizationService localization;

  const CalendarView({
    super.key,
    required this.events,
    required this.localization,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar<EventSummary>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: AppStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            defaultTextStyle: AppStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: AppStyles.bodySmall.copyWith(
              color: Colors.white,
            ),
            titleTextStyle: AppStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
        ),
        const SizedBox(height: 16),
        if (_selectedDay != null) ...[
          Text(
            widget.localization
                .translate('events.eventsOnDate')
                .replaceAll('{date}', _formatDate(_selectedDay!)),
            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildEventsForSelectedDay(_selectedDay!)),
        ],
      ],
    );
  }

  List<EventSummary> _getEventsForDay(DateTime day) {
    return widget.events.where((event) {
      return isSameDay(event.date, day);
    }).toList();
  }

  Widget _buildEventsForSelectedDay(DateTime day) {
    final events = _getEventsForDay(day);

    if (events.isEmpty) {
      return Center(
        child: Text(
          widget.localization.translate('events.noEventsOnDate'),
          style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getEventTypeColor(event.type).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.location!,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _formatTime(event.date),
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.birthday:
        return AppColors.secondary;
      case EventType.wedding:
        return AppColors.primary;
      case EventType.anniversary:
        return AppColors.error;
      case EventType.graduation:
        return AppColors.accent;
      case EventType.holiday:
        return AppColors.success;
      case EventType.babyShower:
        return AppColors.info;
      case EventType.houseWarming:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
