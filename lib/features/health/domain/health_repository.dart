import 'health_place.dart';

abstract class HealthRepository {
  Future<List<HealthPlace>> fetchPlaces();
  Future<List<EmergencyContact>> emergencyContacts();
}
