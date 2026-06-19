import 'package:flutter/material.dart';

class BackupCard extends StatelessWidget {
  const BackupCard({
    super.key,
    required this.isBackingUp,
    required this.isSharing,
    required this.hasTeachers,
    required this.onBackup,
    required this.onShare,
  });

  final bool isBackingUp;
  final bool isSharing;
  final bool hasTeachers;
  final Future<void> Function() onBackup;
  final Future<void> Function(BuildContext context) onShare;

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
            'Backup data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            hasTeachers
                ? 'Choose where to save all teachers and attendance records as an Excel file.'
                : 'Add at least one teacher, then choose where to save an Excel backup.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: isBackingUp || isSharing ? null : onBackup,
                icon: isBackingUp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  isBackingUp ? 'Creating backup...' : 'Backup to Excel',
                ),
              ),
              OutlinedButton.icon(
                onPressed: isBackingUp || isSharing
                    ? null
                    : () => onShare(context),
                icon: isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_outlined),
                label: Text(
                  isSharing ? 'Preparing share...' : 'Share backup',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
