import 'package:flutter/material.dart';

class MemoFormResult {
  MemoFormResult({
    required this.url,
    required this.description,
    this.manualDate,
  });

  final String url;
  final String description;
  final DateTime? manualDate;
}

class MemoFormDialog extends StatefulWidget {
  const MemoFormDialog({super.key});

  static Future<MemoFormResult?> show(BuildContext context) {
    return showDialog<MemoFormResult>(
      context: context,
      builder: (context) => const MemoFormDialog(),
    );
  }

  @override
  State<MemoFormDialog> createState() => _MemoFormDialogState();
}

class _MemoFormDialogState extends State<MemoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save a memo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Source URL',
                  hintText: 'https://instagram.com/...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please paste a link';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Notes or description',
                  hintText: 'Paste the caption or quick notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Event date/time (optional)',
                  hintText: '2025-12-24 19:30',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final manualDate = DateTime.tryParse(_dateController.text.trim());
            Navigator.of(context).pop(
              MemoFormResult(
                url: _urlController.text.trim(),
                description: _descriptionController.text.trim(),
                manualDate: manualDate,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
