import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_boilerplate/core/database/backup_service.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BackupService backupService;
  late Directory tempDir;
  late File testDbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test_');

    // Mock path_provider channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );

    backupService = BackupService();
    testDbFile = File(p.join(tempDir.path, 'test.sqlite'));
    await testDbFile.writeAsString('test database content');
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService', () {
    test('createBackup creates a backup file', () async {
      final backupFile = await backupService.createBackup(testDbFile.path);
      expect(await backupFile.exists(), isTrue);
    });

    test('listBackups returns backup files sorted by name descending',
        () async {
      await backupService.createBackup(testDbFile.path);
      await Future.delayed(const Duration(milliseconds: 10));
      await backupService.createBackup(testDbFile.path);

      final backups = await backupService.listBackups();
      expect(backups.length, 2);
    });

    test('restoreBackup copies backup to target path', () async {
      final backupFile = await backupService.createBackup(testDbFile.path);
      final restorePath = p.join(tempDir.path, 'restored.sqlite');

      await backupService.restoreBackup(backupFile.path, restorePath);

      final restoredFile = File(restorePath);
      expect(await restoredFile.exists(), isTrue);
      expect(
        await restoredFile.readAsString(),
        await testDbFile.readAsString(),
      );
    });

    test('createBackup throws when source file does not exist', () async {
      expect(
        () => backupService.createBackup('/nonexistent/path.sqlite'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
