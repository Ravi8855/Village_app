import 'package:equatable/equatable.dart';

class Temple extends Equatable {
  const Temple({
    required this.id,
    required this.templeName,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.timings,
    this.festivals,
    this.createdAt,
  });

  final String id;
  final String templeName;
  final String description;
  final String? imageUrl;
  final String location;
  final String? timings;
  final String? festivals;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        templeName,
        description,
        imageUrl,
        location,
        timings,
        festivals,
        latitude,
        longitude,
        createdAt,
      ];
}
