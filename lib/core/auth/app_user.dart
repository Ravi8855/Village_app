import 'package:equatable/equatable.dart';

enum UserRole { admin, user }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? fullName;

  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [id, email, role, fullName];
}
