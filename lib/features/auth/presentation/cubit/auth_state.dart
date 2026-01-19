import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class CheckAccountSuccess extends AuthState {
  final String? email;
  final bool emailLinked;

  const CheckAccountSuccess({
    this.email,
    required this.emailLinked,
  });

  @override
  List<Object?> get props => [email, emailLinked];
}

class CheckAccountError extends AuthState {
  final String message;

  const CheckAccountError(this.message);

  @override
  List<Object?> get props => [message];
}

class RequestResetSuccess extends AuthState {
  final String message;

  const RequestResetSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class RequestResetError extends AuthState {
  final String message;

  const RequestResetError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthForgotPasswordEmailRequired extends AuthState {
  final String identifier;

  const AuthForgotPasswordEmailRequired(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class ResetPasswordSuccess extends AuthState {
  final String message;

  const ResetPasswordSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ResetPasswordError extends AuthState {
  final String message;

  const ResetPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

