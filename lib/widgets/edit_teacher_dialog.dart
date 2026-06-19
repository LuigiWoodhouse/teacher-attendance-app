import 'package:flutter/material.dart';

import '../models/teacher_name_draft.dart';

class EditTeacherDialog extends StatefulWidget {
  const EditTeacherDialog({
    super.key,
    required this.initialFirstName,
    required this.initialLastName,
  });

  final String initialFirstName;
  final String initialLastName;

  @override
  State<EditTeacherDialog> createState() => _EditTeacherDialogState();
}

class _EditTeacherDialogState extends State<EditTeacherDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initialFirstName);
    _lastNameController = TextEditingController(text: widget.initialLastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() {
        _showValidation = true;
      });
      return;
    }

    Navigator.of(context).pop(
      TeacherNameDraft(firstName: firstName, lastName: lastName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstNameEmpty = _firstNameController.text.trim().isEmpty;
    final lastNameEmpty = _lastNameController.text.trim().isEmpty;

    return AlertDialog(
      scrollable: true,
      title: const Text('Edit teacher'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstNameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_showValidation) {
                setState(() {});
              }
            },
            decoration: InputDecoration(
              labelText: 'First name',
              border: const OutlineInputBorder(),
              errorText: _showValidation && firstNameEmpty
                  ? 'First name is required.'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameController,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_showValidation) {
                setState(() {});
              }
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Last name',
              border: const OutlineInputBorder(),
              errorText: _showValidation && lastNameEmpty
                  ? 'Last name is required.'
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
