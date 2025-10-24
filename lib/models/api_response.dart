/// API Response Models
/// These models help structure the API responses and make them type-safe

import 'user_model.dart';

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  /// Create success response
  factory ApiResponse.success({
    required String message,
    T? data,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required String message,
    Map<String, dynamic>? errors,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode,
    );
  }

  /// Parse from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'],
      statusCode: json['statusCode'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
      'statusCode': statusCode,
    };
  }
}

/// Authentication response model
class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;
  final String? refreshToken;
  final bool emailVerified;
  final Map<String, dynamic>? errors;

  AuthResponse({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.refreshToken,
    this.emailVerified = false,
    this.errors,
  });

  /// Parse from JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
      refreshToken: json['refreshToken'],
      emailVerified: json['emailVerified'] ?? false,
      errors: json['errors'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'user': user?.toJson(),
      'token': token,
      'refreshToken': refreshToken,
      'emailVerified': emailVerified,
      'errors': errors,
    };
  }
}

/// Registration request model
/// This matches the API expected format:
/// - username: email or phone
/// - fullName: full name
/// - password: password
class RegistrationRequest {
  final String username; // email or phone
  final String fullName; // full name
  final String password; // password

  RegistrationRequest({
    required this.username,
    required this.fullName,
    required this.password,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {'username': username, 'fullName': fullName, 'password': password};
  }

  /// Create from form data
  factory RegistrationRequest.fromForm({
    required String fullName,
    required String username, // email or phone
    required String password,
  }) {
    return RegistrationRequest(
      username: username.trim(),
      fullName: fullName.trim(),
      password: password,
    );
  }
}

/// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  /// Create from form data
  factory LoginRequest.fromForm({
    required String email,
    required String password,
  }) {
    return LoginRequest(email: email.trim().toLowerCase(), password: password);
  }
}

/// Validation error model
class ValidationError {
  final String field;
  final String message;

  ValidationError({required this.field, required this.message});

  /// Parse from JSON
  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'field': field, 'message': message};
  }
}

/// Email verification request
class EmailVerificationRequest {
  final String email;

  EmailVerificationRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// Password reset request
class PasswordResetRequest {
  final String email;

  PasswordResetRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// Password reset with token
class PasswordResetWithTokenRequest {
  final String token;
  final String password;

  PasswordResetWithTokenRequest({required this.token, required this.password});

  Map<String, dynamic> toJson() {
    return {'token': token, 'password': password};
  }
}
