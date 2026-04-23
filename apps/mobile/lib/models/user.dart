import 'shared_models.dart';

class LoginUser extends UserProfile<AppUserRole> {
  const LoginUser({
    required super.id,
    required super.email,
    required super.displayName,
    required super.role,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: AppUserRoleX.fromApiValue(json['role'] as String),
    );
  }
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: parseApiDateTime(
        json['accessTokenExpiresAt'] as String,
      ),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt: parseApiDateTime(
        json['refreshTokenExpiresAt'] as String,
      ),
      user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final LoginUser user;

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
      'refreshToken': refreshToken,
      'refreshTokenExpiresAt': refreshTokenExpiresAt.toUtc().toIso8601String(),
      'user': user.toJson(),
    };
  }
}

extension LoginUserJsonX on LoginUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.apiValue,
    };
  }
}

class PersistedMobileSession {
  const PersistedMobileSession({
    required this.baseUrl,
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  factory PersistedMobileSession.fromJson(Map<String, dynamic> json) {
    return PersistedMobileSession(
      baseUrl: json['baseUrl'] as String,
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: parseApiDateTime(
        json['accessTokenExpiresAt'] as String,
      ),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt: parseApiDateTime(
        json['refreshTokenExpiresAt'] as String,
      ),
      user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  factory PersistedMobileSession.fromLoginResponse({
    required String baseUrl,
    required LoginResponse loginResponse,
  }) {
    return PersistedMobileSession(
      baseUrl: baseUrl,
      accessToken: loginResponse.accessToken,
      accessTokenExpiresAt: loginResponse.accessTokenExpiresAt,
      refreshToken: loginResponse.refreshToken,
      refreshTokenExpiresAt: loginResponse.refreshTokenExpiresAt,
      user: loginResponse.user,
    );
  }

  final String baseUrl;
  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final LoginUser user;

  bool get isAccessTokenExpired =>
      accessTokenExpiresAt.isBefore(DateTime.now().toUtc());

  bool get isRefreshTokenExpired =>
      refreshTokenExpiresAt.isBefore(DateTime.now().toUtc());

  LoginResponse toLoginResponse() {
    return LoginResponse(
      accessToken: accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt,
      refreshToken: refreshToken,
      refreshTokenExpiresAt: refreshTokenExpiresAt,
      user: user,
    );
  }

  PersistedMobileSession copyWith({
    String? baseUrl,
    String? accessToken,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    DateTime? refreshTokenExpiresAt,
    LoginUser? user,
  }) {
    return PersistedMobileSession(
      baseUrl: baseUrl ?? this.baseUrl,
      accessToken: accessToken ?? this.accessToken,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'accessToken': accessToken,
      'accessTokenExpiresAt': accessTokenExpiresAt.toUtc().toIso8601String(),
      'refreshToken': refreshToken,
      'refreshTokenExpiresAt': refreshTokenExpiresAt.toUtc().toIso8601String(),
      'user': user.toJson(),
    };
  }
}
