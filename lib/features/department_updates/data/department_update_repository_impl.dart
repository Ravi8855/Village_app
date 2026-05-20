import '../../../core/domain/department.dart';
import '../domain/department_update.dart';
import '../domain/department_update_repository.dart';
import 'department_update_datasource.dart';

class DepartmentUpdateRepositoryImpl implements DepartmentUpdateRepository {
  DepartmentUpdateRepositoryImpl(this._datasource);

  final DepartmentUpdateDatasource _datasource;

  @override
  Future<List<DepartmentUpdate>> fetchByDepartment(
    VillageDepartment department,
  ) =>
      _datasource.fetchByDepartment(department);

  @override
  Future<List<DepartmentUpdate>> fetchAll() => _datasource.fetchAll();

  @override
  Future<void> create(DepartmentUpdate update) async {
    await _datasource.insert({
      'department': update.department.dbValue,
      'title': update.title,
      'description': update.description,
      'image_url': update.imageUrl,
      'created_by': update.createdBy,
    });
  }

  @override
  Future<void> update(DepartmentUpdate update) async {
    await _datasource.updateRow(update.id, {
      'title': update.title,
      'description': update.description,
      'image_url': update.imageUrl,
    });
  }

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<String> uploadImage({
    required VillageDepartment department,
    required String filePath,
  }) =>
      _datasource.uploadImage(department: department, filePath: filePath);
}
