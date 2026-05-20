import '../../../core/domain/department.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../models/app_user_model.dart';
import '../domain/department_notice.dart';
import 'department_notice_datasource.dart';

/// Supabase-backed department notices with app-side permission checks.
class DepartmentNoticeRepository {
  DepartmentNoticeRepository(this._datasource);

  final DepartmentNoticeDatasource _datasource;

  Future<List<DepartmentNotice>> getNoticesByDepartment(
    String department,
  ) =>
      _datasource.fetchByDepartment(department);

  Stream<List<DepartmentNotice>> watchNoticesByDepartment(
    String department,
  ) =>
      _datasource.watchByDepartment(department);

  Future<DepartmentNotice> createNotice({
    required AppUserModel actor,
    required String department,
    required String title,
    required String description,
  }) async {
    _assertCanModify(actor, department);
    return _datasource.insert({
      'department': department,
      'title': title.trim(),
      'description': description.trim(),
      'created_by': actor.uid,
    });
  }

  Future<DepartmentNotice> updateNotice({
    required AppUserModel actor,
    required String noticeId,
    required String title,
    required String description,
  }) async {
    final existing = await _datasource.fetchById(noticeId);
    if (existing == null) {
      throw StateError('Notice not found.');
    }
    _assertCanModify(actor, existing.department);
    return _datasource.updateRow(noticeId, {
      'title': title.trim(),
      'description': description.trim(),
    });
  }

  Future<void> deleteNotice({
    required AppUserModel actor,
    required String noticeId,
  }) async {
    final existing = await _datasource.fetchById(noticeId);
    if (existing == null) return;
    _assertCanModify(actor, existing.department);
    await _datasource.delete(noticeId);
  }

  void _assertCanModify(AppUserModel? actor, String department) {
    final villageDept = VillageDepartment.fromDbValue(department);
    if (villageDept == null) {
      throw StateError('Invalid department.');
    }
    if (!PermissionService.canManageDepartment(actor, villageDept)) {
      throw StateError(
        'You do not have permission to manage notices for this department.',
      );
    }
  }
}
