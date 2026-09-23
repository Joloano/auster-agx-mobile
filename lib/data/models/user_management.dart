import 'auth_user.dart';

class ProfileUpdateResult {
  const ProfileUpdateResult({
    required this.user,
    required this.accessToken,
    required this.expiresIn,
  });

  final AuthUser user;
  final String accessToken;
  final int expiresIn;
}

class CreatedUser {
  const CreatedUser({
    required this.user,
    required this.provisionedPassword,
    required this.temporaryPassword,
  });

  factory CreatedUser.fromJson(Map<String, dynamic> json) {
    return CreatedUser(
      user: AuthUser.fromJson({
        ...json,
        'ativo': true,
        'authority': json['authority'] ?? json['perfil'],
      }),
      provisionedPassword: json['senhaProvisionada'] as String,
      temporaryPassword: (json['senhaTemporaria'] as bool?) ?? false,
    );
  }

  final AuthUser user;
  final String provisionedPassword;
  final bool temporaryPassword;
}

class TemporaryPasswordResult {
  const TemporaryPasswordResult({
    required this.email,
    required this.password,
  });

  factory TemporaryPasswordResult.fromJson(Map<String, dynamic> json) {
    return TemporaryPasswordResult(
      email: json['email'] as String,
      password: json['senhaTemporaria'] as String,
    );
  }

  final String email;
  final String password;
}
