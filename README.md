# Teacher Attendance App

A Flutter app for tracking teacher attendance day by day.

The app lets you add teachers, log attendance statuses for specific dates, review attendance history, and export the saved data as an Excel backup. Each teacher card shows a quick summary of present, absent, late, and holiday counts, and older attendance entries can be revealed with a `See more` button when the history grows beyond five logged days.

## What The App Does

- Add teachers with first and last names.
- Log attendance for any date.
- Mark a teacher as present, absent, late, or on holiday for today in one tap.
- Edit or delete previously logged attendance entries.
- View per-teacher attendance totals.
- View an end-of-term summary across all saved teachers.
- Expand older attendance history with `See more` and collapse it with `Show less`.
- Save attendance data locally on the device using `shared_preferences`.
- Export and share attendance records as an Excel file.

## Main Features

### Teacher Register

Teachers are stored locally and displayed as individual cards. Each card includes:

- The teacher name
- Attendance totals by status
- Quick actions for today's attendance
- A dated attendance log

### Attendance Tracking

Each attendance entry is saved with:

- A calendar date
- One status: `Present`, `Absent`, `Late`, or `Holiday`

If a teacher has more than five attendance entries, the card initially shows the latest five and reveals the rest through the `See more` button.

### Backup And Sharing

The app can generate an Excel backup containing:

- Teacher names
- Totals by attendance status
- Date ranges for each status
- Total logged entries

The backup can be saved locally or shared through the device share sheet.

## Tech Stack

- Flutter
- Dart
- Material 3
- `shared_preferences` for local persistence
- `excel` for spreadsheet export
- `file_picker` for backup file selection
- `share_plus` for sharing backups

## Local Tool Versions

- Flutter: `3.35.5`
- Dart: `3.9.2`
- Java: `17.0.8`

## Project Structure

The project is organized to keep responsibilities separated:

- [lib/main.dart](./lib/main.dart): app entry point
- [lib/app](./lib/app): app shell and main page
- [lib/models](./lib/models): attendance and teacher domain models
- [lib/services](./lib/services): persistence and backup abstractions
- [lib/widgets](./lib/widgets): reusable UI pieces
- [lib/utils](./lib/utils): shared date and formatting helpers

## Running The App

1. Install Flutter and make sure your SDK is available on `PATH`.
2. Run `flutter pub get`.
3. Start the app with `flutter run`.

## Notes

- Attendance data is stored locally on the device.
- Exported backups are generated as `.xlsx` files.
- The app currently focuses on offline teacher attendance management rather than remote sync or multi-user access.
