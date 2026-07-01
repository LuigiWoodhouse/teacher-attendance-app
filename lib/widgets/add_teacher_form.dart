import 'package:flutter/material.dart';

import '../models/attendance_term.dart';
import 'year_picker_field.dart';

class AddTeacherForm extends StatelessWidget {
  const AddTeacherForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.yearOptions,
    required this.selectedYear,
    required this.onYearChanged,
    required this.selectedTerm,
    required this.onTermChanged,
    required this.onAddTeacher,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final List<int> yearOptions;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final AttendanceTerm selectedTerm;
  final ValueChanged<AttendanceTerm> onTermChanged;
  final Future<void> Function() onAddTeacher;

  @override
  Widget build(BuildContext context) {
    final firstYear = yearOptions.reduce((value, element) {
      return value < element ? value : element;
    });
    final lastYear = yearOptions.reduce((value, element) {
      return value > element ? value : element;
    });

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
          YearPickerField(
            key: ValueKey('add-teacher-year-$selectedYear'),
            selectedYear: selectedYear,
            firstYear: firstYear,
            lastYear: lastYear,
            onChanged: onYearChanged,
            dialogTitle: 'Select teacher year',
          ),
          const SizedBox(height: 12),
          Text(
            'Term',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AttendanceTerm.values.map((term) {
              final isSelected = term == selectedTerm;
              return ChoiceChip(
                selected: isSelected,
                label: Text(term.label),
                onSelected: (_) => onTermChanged(term),
              );
            }).toList(growable: false),
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
