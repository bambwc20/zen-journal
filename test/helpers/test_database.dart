import 'package:drift/native.dart';
import 'package:flutter_boilerplate/core/database/app_database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}
