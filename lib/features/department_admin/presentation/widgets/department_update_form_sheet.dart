import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/domain/department.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../department_updates/domain/department_update.dart';
import '../../../department_updates/presentation/department_update_providers.dart';

class DepartmentUpdateFormSheet extends ConsumerStatefulWidget {
  const DepartmentUpdateFormSheet({
    super.key,
    required this.department,
    this.existing,
    this.skipPermissionCheck = false,
  });

  final VillageDepartment department;
  final DepartmentUpdate? existing;

  /// Super-admin content tab bypasses dept-scoped checks.
  final bool skipPermissionCheck;

  @override
  ConsumerState<DepartmentUpdateFormSheet> createState() =>
      _DepartmentUpdateFormSheetState();
}

class _DepartmentUpdateFormSheetState
    extends ConsumerState<DepartmentUpdateFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _imagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _description =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null ? 'New notice' : 'Edit notice',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_outlined),
              label: Text(_imagePath == null ? 'Attach image' : 'Image selected'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.existing == null ? 'Publish' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (title.isEmpty || description.isEmpty) return;

    setState(() => _saving = true);
    try {
      if (!widget.skipPermissionCheck) {
        PermissionService.assertCanManageDepartment(
          ref.read(authProvider).user,
          widget.department,
        );
      }
      final repo = ref.read(departmentUpdateRepositoryProvider);
      final userId = ref.read(authProvider).user?.uid;
      String? imageUrl = widget.existing?.imageUrl;

      if (_imagePath != null) {
        imageUrl = await repo.uploadImage(
          department: widget.department,
          filePath: _imagePath!,
        );
      }

      if (widget.existing == null) {
        await repo.create(
          DepartmentUpdate(
            id: '',
            department: widget.department,
            title: title,
            description: description,
            imageUrl: imageUrl,
            createdBy: userId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await repo.update(
          DepartmentUpdate(
            id: widget.existing!.id,
            department: widget.department,
            title: title,
            description: description,
            imageUrl: imageUrl,
            createdBy: widget.existing!.createdBy,
            createdAt: widget.existing!.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
