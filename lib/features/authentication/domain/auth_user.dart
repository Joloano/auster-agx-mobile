class AuthUser {
  const AuthUser({
    required this.userId,
    required this.nome,
    required this.email,
    required this.perfil,
    required this.authority,
    required this.ativo,
    required this.deveAlterarSenha,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      perfil: json['perfil'] as String,
      authority: json['authority'] as String,
      ativo: (json['ativo'] as bool?) ?? true,
      deveAlterarSenha: json['deveAlterarSenha'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nome': nome,
      'email': email,
      'perfil': perfil,
      'authority': authority,
      'ativo': ativo,
      'deveAlterarSenha': deveAlterarSenha,
    };
  }

  final String userId;
  final String nome;
  final String email;
  final String perfil;
  final String authority;
  final bool ativo;
  final bool deveAlterarSenha;
}
