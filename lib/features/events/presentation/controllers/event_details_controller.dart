import 'package:get/get.dart';
import 'package:wish_listy/features/events/data/models/event_attendee_model.dart';
import 'package:wish_listy/features/events/data/models/event_linked_wishlist_model.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';

class EventDetailsController extends GetxController {
  final EventRepository _eventRepository;

  EventDetailsController({EventRepository? eventRepository})
      : _eventRepository = eventRepository ?? EventRepository();

  final RxList<EventAttendeeModel> attendees = <EventAttendeeModel>[].obs;
  final RxList<EventLinkedWishlistModel> linkedWishlists =
      <EventLinkedWishlistModel>[].obs;

  final Rx<EventAttendeeStatsModel?> attendeeStats =
      Rx<EventAttendeeStatsModel?>(null);

  final RxBool isLoadingAttendees = false.obs;
  final RxBool isLoadingWishlists = false.obs;

  Future<void> fetchAttendees(String eventId) async {
    isLoadingAttendees.value = true;
    try {
      final (list, stats) = await _eventRepository.getEventAttendees(eventId);
      attendees.assignAll(list);
      attendeeStats.value = stats;
    } finally {
      isLoadingAttendees.value = false;
    }
  }

  Future<void> fetchLinkedWishlists(String eventId) async {
    isLoadingWishlists.value = true;
    try {
      final list = await _eventRepository.getEventLinkedWishlists(eventId);
      linkedWishlists.assignAll(list);
    } finally {
      isLoadingWishlists.value = false;
    }
  }

  Future<void> loadAll(String eventId) async {
    isLoadingAttendees.value = true;
    isLoadingWishlists.value = true;
    try {
      final results = await Future.wait([
        _eventRepository.getEventAttendees(eventId),
        _eventRepository.getEventLinkedWishlists(eventId),
      ]);

      final attendeesRes =
          results[0] as (List<EventAttendeeModel>, EventAttendeeStatsModel);
      attendees.assignAll(attendeesRes.$1);
      attendeeStats.value = attendeesRes.$2;

      linkedWishlists.assignAll(results[1] as List<EventLinkedWishlistModel>);
    } finally {
      isLoadingAttendees.value = false;
      isLoadingWishlists.value = false;
    }
  }
}

