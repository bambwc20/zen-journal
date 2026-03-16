import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_service.g.dart';

class BackupService {
  static const int maxBackups = 7;
  static const String backupDirName = 'backups';

  Future<String> get _backupDirPath async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, backupDirName);
  }

  Future<Directory> get _backupDir async {
    final dir = Directory(await _backupDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> createBackup(String dbPath) async {
    final dir = await _backupDir;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File(p.join(dir.path, 'backup_$timestamp.sqlite'));
    final sourceFile = File(dbPath);

    if (!await sourceFile.exists()) {
      throw FileSystemException('Database file not found', dbPath);
    }

    await sourceFile.copy(backupFile.path);
    await _rotateBackups();
    return backupFile;
  }

  Future<void> restoreBackup(String backupPath, String dbPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw FileSystemException('Backup file not found', backupPath);
    }
    await backupFile.copy(dbPath);
  }

  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _backupDir;
    if (!await dir.exists()) return [];
    final files = await dir.list().toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<void> _rotateBackups() async {
    final backups = await listBackups();
    if (backups.length > maxBackups) {
      for (final old in backups.sublist(maxBackups)) {
        await old.delete();
      }
    }
  }
}

@riverpod
BackupService backupService(Ref ref) {
  return BackupService();
}
