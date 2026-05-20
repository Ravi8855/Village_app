import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../shared/utils/form_toast.dart';
import '../../domain/department_notice.dart';
import '../water_notice_providers.dart';

/// Create or edit a water supply notice (title + description only).
class WaterNoticeFormSheet extends ConsumerStatefulWidget {
  const WaterNoticeFormSheet({super.key, this.existing});

  final DepartmentNotice? existing;

  @override
  ConsumerState<WaterNoticeFormSheet> createState() =>
      _WaterNoticeFormSheetState();
}

class _WaterNoticeFormSheetState extends ConsumerState<WaterNoticeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  bool _saving = false;
  bool _showValidation = false;

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

  Future<void> _save() async {
    setState(() => _showValidation = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      showFormToast(context, 'You must be signed in.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(departmentNoticeRepositoryProvider);
      if (widget.existing == null) {
        await repo.createNotice(
          actor: user,
          department: DepartmentNotice.waterSupplyDepartment,
          title: _title.text,
          description: _description.text,
        );
      } else {
        await repo.updateNotice(
          actor: user,
          noticeId: widget.existing!.id,
          title: _title.text,
          description: _description.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showFormError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      child: Form(
        key: _formKey,
        autovalidateMode: _showValidation
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null
                    ? 'New water supply notice'
                    : 'Edit notice',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Department: Water Supply · Posted as you',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
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
                    : Text(widget.existing == null ? 'Publish notice' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
