import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/department.dart';
import '../data/department_update_datasource.dart';
import '../data/department_update_repository_impl.dart';
import '../domain/department_update.dart';
import '../domain/department_update_repository.dart';

final departmentUpdateDatasourceProvider =
    Provider<DepartmentUpdateDatasource>((ref) {
  return DepartmentUpdateDatasource();
});

final departmentUpdateRepositoryProvider =
    Provider<DepartmentUpdateRepository>((ref) {
  return DepartmentUpdateRepositoryImpl(
    ref.watch(departmentUpdateDatasourceProvider),
  );
});

final departmentUpdatesProvider =
    FutureProvider.family<List<DepartmentUpdate>, VillageDepartment>(
  (ref, department) {
    return ref
        .watch(departmentUpdateRepositoryProvider)
        .fetchByDepartment(department);
  },
);

final allDepartmentUpdatesProvider =
    FutureProvider<List<DepartmentUpdate>>((ref) {
  return ref.watch(departmentUpdateRepositoryProvider).fetchAll();
});
