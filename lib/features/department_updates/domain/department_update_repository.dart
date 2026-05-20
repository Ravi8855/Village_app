import '../../../core/domain/department.dart';
import 'department_update.dart';

abstract class DepartmentUpdateRepository {
  Future<List<DepartmentUpdate>> fetchByDepartment(VillageDepartment department);
  Future<List<DepartmentUpdate>> fetchAll();
  Future<void> create(DepartmentUpdate update);
  Future<void> update(DepartmentUpdate update);
  Future<void> delete(String id);
  Future<String> uploadImage({
    required VillageDepartment department,
    required String filePath,
  });
}
