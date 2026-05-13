import '../../../core/constants/location_constants.dart';
import '../domain/health_place.dart';
import '../domain/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  @override
  Future<List<HealthPlace>> fetchPlaces() async {
    const baseLat = NaganoorLocation.latitude;
    const baseLng = NaganoorLocation.longitude;
    return [
      HealthPlace(
        id: 'hosp-1',
        name: 'Primary Health Centre — Naganoor',
        address: 'Near Panchayat office, Naganoor',
        timings: 'Mon–Sat · 9:00am – 4:00pm',
        phone: '08452200000',
        latitude: baseLat + 0.002,
        longitude: baseLng + 0.0015,
        type: HealthPlaceType.hospital,
      ),
      HealthPlace(
        id: 'clinic-1',
        name: 'Village Wellness Clinic',
        address: 'Main road, opposite milk booth',
        timings: 'Daily · 8:00am – 1:00pm, 4:00pm – 8:00pm',
        phone: '09876543210',
        latitude: baseLat - 0.001,
        longitude: baseLng + 0.002,
        type: HealthPlaceType.clinic,
      ),
      HealthPlace(
        id: 'pharm-1',
        name: 'Sri Raghava Medical Stores',
        address: 'Bus stand circle',
        timings: 'Daily · 8:30am – 10:00pm',
        phone: '09121112222',
        latitude: baseLat + 0.001,
        longitude: baseLng - 0.002,
        type: HealthPlaceType.pharmacy,
      ),
    ];
  }

  @override
  Future<List<EmergencyContact>> emergencyContacts() async {
    return const [
      EmergencyContact(label: 'District ambulance', phone: '108'),
      EmergencyContact(label: 'Fire & rescue', phone: '101'),
      EmergencyContact(label: 'Women helpline', phone: '181'),
      EmergencyContact(label: 'Village duty officer', phone: '09490011223'),
    ];
  }
}
