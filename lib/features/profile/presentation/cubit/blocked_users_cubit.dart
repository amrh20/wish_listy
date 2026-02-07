import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/friends/data/models/user_model.dart';
import 'package:wish_listy/features/profile/data/repository/privacy_repository.dart';

/// State for blocked users screen.
sealed class BlockedUsersState extends Equatable {
  const BlockedUsersState();

  @override
  List<Object?> get props => [];
}

class BlockedUsersLoading extends BlockedUsersState {}

class BlockedUsersLoaded extends BlockedUsersState {
  final List<User> users;

  const BlockedUsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class BlockedUsersError extends BlockedUsersState {
  final String message;

  const BlockedUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Cubit for blocked users list: load and unblock.
class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  final PrivacyRepository _repository;

  BlockedUsersCubit({PrivacyRepository? repository})
      : _repository = repository ?? PrivacyRepository(),
        super(BlockedUsersLoading());

  /// Load blocked users from API.
  Future<void> loadBlockedUsers() async {
    emit(BlockedUsersLoading());
    try {
      final users = await _repository.getBlockedUsers();
      emit(BlockedUsersLoaded(users));
    } on ApiException catch (e) {
      emit(BlockedUsersError(e.message));
    } catch (e) {
      emit(BlockedUsersError(e.toString()));
    }
  }

  /// Unblock a user and remove from list on success.
  /// On failure keeps current list; UI should show Snackbar.
  Future<bool> unblockUser(String userId) async {
    final current = state;
    if (current is! BlockedUsersLoaded) return false;
    try {
      await _repository.unblockUser(userId);
      final updated = current.users.where((u) => u.id != userId).toList();
      emit(BlockedUsersLoaded(updated));
      return true;
    } catch (_) {
      return false;
    }
  }
}
