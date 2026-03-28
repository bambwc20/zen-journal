import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_boilerplate/core/database/backup_service.dart';
import 'package:flutter_boilerplate/features/zen_journal/domain/models/journal_entry.dart';

part 'backup_data.g.dart';

/// Use case for encrypted data backup operations and data export.
class BackupData {
  final BackupService _backupService;

  BackupData(this._backupService);

  /// Creates a manual local backup of the database.
  Future<String> createLocalBackup() async {
    final dbPath = await _getDbPath();
    final backupFile = await _backupService.createBackup(dbPath);
    return backupFile.path;
  }

  /// Restores the database from a backup file.
  Future<void> restoreFromBackup(String backupPath) async {
    final dbPath = await _getDbPath();
    await _backupService.restoreBackup(backupPath, dbPath);
  }

  /// Lists all available local backups, sorted by date (newest first).
  Future<List<FileSystemEntity>> listBackups() async {
    return await _backupService.listBackups();
  }

  Future<String> _getDbPath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'app.sqlite');
  }

  /// Exports entries as a plain text file.
  Future<File> exportToTxt(List<JournalEntry> entries) async {
    final buffer = StringBuffer();
    buffer.writeln('ZenJournal Export');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${entries.length}');
    buffer.writeln('${'=' * 60}\n');

    for (final entry in entries) {
      buffer.writeln('Date: ${_formatDate(entry.createdAt)}');
      buffer.writeln('Mood: ${_moodLabel(entry.moodLevel)}');
      buffer.writeln();
      buffer.writeln(entry.plainText);
      buffer.writeln('\n${'-' * 40}\n');
    }

    return _writeExportFile('zenjournal_export.txt', buffer.toString());
  }

  /// Exports entries as JSON.
  Future<File> exportToJson(List<JournalEntry> entries) async {
    final data = entries.map((e) => {
      'id': e.id,
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
      'moodLevel': e.moodLevel,
      'plainText': e.plainText,
    }).toList();

    final jsonStr = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'totalEntries': entries.length,
      'entries': data,
    });

    return _writeExportFile('zenjournal_export.json', jsonStr);
  }

  /// Exports entries as CSV.
  Future<File> exportToCsv(List<JournalEntry> entries) async {
    final buffer = StringBuffer();
    buffer.writeln('Date,Mood,Content');

    for (final entry in entries) {
      final content = entry.plainText
          .replaceAll('"', '""')
          .replaceAll('\n', ' ');
      buffer.writeln(
        '"${_formatDate(entry.createdAt)}",'
        '"${_moodLabel(entry.moodLevel)}",'
        '"$content"',
      );
    }

    return _writeExportFile('zenjournal_export.csv', buffer.toString());
  }

  /// Shares an export file using the system share sheet.
  Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }

  Future<File> _writeExportFile(String filename, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content);
    return file;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _moodLabel(int level) {
    const labels = ['', 'Very Bad', 'Bad', 'Neutral', 'Good', 'Very Good'];
    return level >= 1 && level <= 5 ? labels[level] : 'Unknown';
  }
}

@riverpod
BackupData backupData(Ref ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupData(backupService);
}
