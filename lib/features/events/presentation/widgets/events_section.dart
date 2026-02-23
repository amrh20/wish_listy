import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/events/data/models/event.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

class EventsSection extends StatefulWidget {
  final List<Event> events;
  final VoidCallback? onSeeAll;

  const EventsSection({
    super.key,
    required this.events,
    this.onSeeAll,
  });

  @override
  State<EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends State<EventsSection>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  int? _hoveredIndex; // Added hover state

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.events.isEmpty)
          _buildEmptyState(context)
        else
          SizedBox(
            height: 160, // Increased height to prevent overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: widget.events.length,
              itemBuilder: (context, index) {
                final event = widget.events[index];
                return _buildEventCard(event, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = Provider.of<LocalizationService>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 50,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text(
            t.translate('events.noUpcomingEvents'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, int index) {
    final isHovered = _hoveredIndex == index;
    
    return GestureDetector( // Added GestureDetector for tap
      onTap: () {
        // Navigate to Event Details Screen
        AppRoutes.pushNamed(
          context,
          AppRoutes.eventDetails,
          arguments: {
            'eventId': event.id,
          },
        );
      },
      child: MouseRegion( // Added MouseRegion for cursor pointer
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer( // Added AnimatedContainer for smooth transitions
          duration: const Duration(milliseconds: 200),
          transform: isHovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
          width: 300,
          decoration: AppStyles.glassCardDecoration.copyWith(
            boxShadow: [
              BoxShadow(
                color: event.iconColor.withOpacity(isHovered ? 0.3 : 0.2),
                blurRadius: isHovered ? 25 : 20,
                offset: Offset(0, isHovered ? 10 : 8),
              ),
            ],
          ),
          child: ClipRRect( // Added ClipRRect to prevent overflow
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Event Icon with Glow
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          event.iconColor.withOpacity(isHovered ? 0.3 : 0.2),
                          event.iconColor.withOpacity(isHovered ? 0.2 : 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: event.iconColor.withOpacity(isHovered ? 0.4 : 0.3),
                        width: isHovered ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: event.iconColor.withOpacity(isHovered ? 0.4 : 0.3),
                          blurRadius: isHovered ? 20 : 15,
                          offset: Offset(0, isHovered ? 8 : 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        event.icon,
                        style: TextStyle(
                          fontSize: isHovered ? 30 : 28,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Event Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.title,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.formattedDate,
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Participants with Beautiful Avatars
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          ...event.participants.take(3).map((participant) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: isHovered ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.textTertiary.withOpacity(0.1),
                                    blurRadius: isHovered ? 12 : 8,
                                    offset: Offset(0, isHovered ? 4 : 2),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: isHovered ? 20 : 18,
                                backgroundImage: NetworkImage(participant),
                                onBackgroundImageError: (exception, stackTrace) {
                                  // Handle error
                                },
                              ),
                            ),
                          )),
                          if (event.participants.length > 3)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: isHovered ? 40 : 36,
                              height: isHovered ? 40 : 36,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(isHovered ? 0.4 : 0.3),
                                    blurRadius: isHovered ? 12 : 8,
                                    offset: Offset(0, isHovered ? 6 : 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '+${event.participants.length - 3}',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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
