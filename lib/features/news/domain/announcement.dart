import 'package:equatable/equatable.dart';

import 'announcement_category.dart';

class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    this.imageUrl,
    this.createdBy,
    this.updatedAt,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final AnnouncementCategory category;
  final String? imageUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  /// Backward-compatible alias used by existing UI snippets.
  String get body => description;
  DateTime get publishedAt => createdAt;

  Announcement copyWith({
    String? id,
    String? title,
    String? description,
    AnnouncementCategory? category,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        imageUrl,
        createdBy,
        createdAt,
        updatedAt,
        isActive,
      ];
}
