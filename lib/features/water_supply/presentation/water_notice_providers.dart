import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/department_notice_datasource.dart';
import '../data/department_notice_repository.dart';
import '../domain/department_notice.dart';

final departmentNoticeDatasourceProvider =
    Provider<DepartmentNoticeDatasource>((ref) {
  return DepartmentNoticeDatasource();
});

final departmentNoticeRepositoryProvider =
    Provider<DepartmentNoticeRepository>((ref) {
  return DepartmentNoticeRepository(
    ref.watch(departmentNoticeDatasourceProvider),
  );
});

/// Realtime water supply notices (newest first).
final waterNoticesStreamProvider =
    StreamProvider<List<DepartmentNotice>>((ref) {
  return ref
      .watch(departmentNoticeRepositoryProvider)
      .watchNoticesByDepartment(DepartmentNotice.waterSupplyDepartment);
});
