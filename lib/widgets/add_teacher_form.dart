import 'package:flutter/material.dart';

class AddTeacherForm extends StatelessWidget {
  const AddTeacherForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.onAddTeacher,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final Future<void> Function() onAddTeacher;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add teacher',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: firstNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'First name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: lastNameController,
            onSubmitted: (_) => onAddTeacher(),
            decoration: const InputDecoration(
              labelText: 'Last name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddTeacher,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add teacher'),
            ),
          ),
        ],
      ),
    );
  }
}
