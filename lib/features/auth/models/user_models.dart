class UserModel {
  final String id; // UUID dari Auth
  final String email;
  final String username;
  final String role; // Admin, Petugas, Peminjam

  UserModel({required this.id, required this.email, required this.username, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      role: json['role'],
    );
  }
}