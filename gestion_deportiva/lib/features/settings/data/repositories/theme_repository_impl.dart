import 'package:flutter/material.dart';

import '../../domain/repositories/theme_repository.dart';
import '../datasources/theme_local_datasource.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource localDataSource;

  ThemeRepositoryImpl({required this.localDataSource});

  @override
  Future<ThemeMode> getThemeMode() => localDataSource.getThemeMode();

  @override
  Future<void> saveThemeMode(ThemeMode mode) =>
      localDataSource.saveThemeMode(mode);
}
