class LoginUser {
  const LoginUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String role;
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
