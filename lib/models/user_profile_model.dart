class UserProfile {
  final int userId;
  String name;
  final String email;
  final String role;
  final String token;
  String? linkAnhDaiDien;
  String? tieuSu;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.linkAnhDaiDien,
    this.tieuSu,
  });
}
