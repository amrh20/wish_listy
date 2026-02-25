import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/models/reservation_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';

/// States for Pending Reservations section on Home.
abstract class PendingReservationsState extends Equatable {
  const PendingReservationsState();

  @override
  List<Object?> get props => [];
}

class PendingReservationsInitial extends PendingReservationsState {
  const PendingReservationsInitial();
}

class PendingReservationsLoading extends PendingReservationsState {
  const PendingReservationsLoading();
}

class PendingReservationsSuccess extends PendingReservationsState {
  final List<PendingReservation> reservations;

  const PendingReservationsSuccess(this.reservations);

  @override
  List<Object?> get props => [reservations];
}

class PendingReservationsError extends PendingReservationsState {
  final String message;

  const PendingReservationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class PendingReservationsCubit extends Cubit<PendingReservationsState> {
  final WishlistRepository _wishlistRepository;

  PendingReservationsCubit({WishlistRepository? wishlistRepository})
      : _wishlistRepository = wishlistRepository ?? WishlistRepository(),
        super(const PendingReservationsInitial());

  /// Load pending reservations from API.
  Future<void> loadPendingReservations({bool showLoading = true}) async {
    // إظهر حالة التحميل بس في أول مرة أو لما نطلبها صراحة
    if (showLoading || state is PendingReservationsInitial) {
      emit(const PendingReservationsLoading());
    }
    try {
      final reservations = await _wishlistRepository.fetchPendingReservations();
      emit(PendingReservationsSuccess(reservations));
    } on ApiException catch (e) {
      emit(PendingReservationsError(e.message));
    } catch (e) {
      emit(const PendingReservationsError(
        'Failed to load pending reservations. Please try again.',
      ));
    }
  }

  /// Background refresh بدون إظهار skeleton (يستخدم من HomeScreen.refreshHome).
  Future<void> refresh() => loadPendingReservations(showLoading: false);
}

