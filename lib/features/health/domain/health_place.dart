import 'package:equatable/equatable.dart';

enum HealthPlaceType { hospital, clinic, pharmacy }

class HealthPlace extends Equatable {
  const HealthPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.timings,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  final String id;
  final String name;
  final String address;
  final String timings;
  final String phone;
  final double latitude;
  final double longitude;
  final HealthPlaceType type;

  @override
  List<Object?> get props =>
      [id, name, address, timings, phone, latitude, longitude, type];
}

class EmergencyContact extends Equatable {
  const EmergencyContact({required this.label, required this.phone});

  final String label;
  final String phone;

  @override
  List<Object?> get props => [label, phone];
}
