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
  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final LoginUser user;
}
