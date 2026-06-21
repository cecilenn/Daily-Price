import 'dart:developer';

import 'package:sqflite/sqflite.dart';

class LocalDbSchema {
  static const databaseName = 'daily_price.db';
  static const version = 9;

  const LocalDbSchema._();

  static Future<void> create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assets(
        id TEXT PRIMARY KEY,
        asset_name TEXT NOT NULL,
        purchase_price REAL,
        purchase_date INTEGER NOT NULL,
        is_pinned INTEGER DEFAULT 0,
        category TEXT DEFAULT '未分类',
        tags TEXT DEFAULT '[]',
        created_at INTEGER NOT NULL,
        status INTEGER DEFAULT 0,
        expected_lifespan_days INTEGER,
        expire_date INTEGER,
        sold_price REAL,
        sold_date INTEGER,
        avatar_path TEXT,
        avatar_bg_color INTEGER,
        avatar_text TEXT,
        avatar_icon_code_point INTEGER,
        exclude_from_total INTEGER DEFAULT 0,
        exclude_from_daily INTEGER DEFAULT 0,
        ownership_type TEXT DEFAULT 'buyout',
        renewals TEXT DEFAULT '[]',
        consumables TEXT DEFAULT '[]',
        replacements TEXT DEFAULT '[]'
      )
    ''');
    await _createCheckTables(db);
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await _addAvatarV3Fields(db);
    }

    if (oldVersion < 6) {
      final columnNames = await _assetColumnNames(db);

      if (!columnNames.contains('ownership_type')) {
        await db.execute(
          "ALTER TABLE assets ADD COLUMN ownership_type TEXT DEFAULT 'buyout'",
        );
      }

      await db.execute(
        "UPDATE assets SET ownership_type = 'subscription' WHERE category = 'subscription'",
      );
      await db.execute(
        "UPDATE assets SET category = '未分类' WHERE category IN ('physical', 'virtual', 'subscription')",
      );

      log('========== [LocalDb] V6 自定义分类 + ownership_type 升级完成 ==========');
    }

    if (oldVersion < 7) {
      final columnNames = await _assetColumnNames(db);

      if (!columnNames.contains('renewals')) {
        await db.execute(
          "ALTER TABLE assets ADD COLUMN renewals TEXT DEFAULT '[]'",
        );
      }
      log('========== [LocalDb] V7 续费记录字段升级完成 ==========');
    }

    if (oldVersion < 8) {
      await _createCheckTables(db);
      log('========== [LocalDb] V8 检查功能表创建完成 ==========');
    }

    if (oldVersion < 9) {
      final columnNames = await _assetColumnNames(db);

      if (!columnNames.contains('consumables')) {
        await db.execute(
          "ALTER TABLE assets ADD COLUMN consumables TEXT DEFAULT '[]'",
        );
      }

      if (!columnNames.contains('replacements')) {
        await db.execute(
          "ALTER TABLE assets ADD COLUMN replacements TEXT DEFAULT '[]'",
        );
      }

      log('========== [LocalDb] V9 耗材追踪字段升级完成 ==========');
    }
  }

  static Future<void> _createCheckTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS check_sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        status INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS check_items (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        asset_id TEXT NOT NULL,
        asset_snapshot TEXT NOT NULL,
        confirmed_at INTEGER,
        FOREIGN KEY (session_id) REFERENCES check_sessions(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _addAvatarV3Fields(Database db) async {
    final columnNames = await _assetColumnNames(db);

    if (!columnNames.contains('avatar_bg_color')) {
      await db.execute('ALTER TABLE assets ADD COLUMN avatar_bg_color INTEGER');
    }

    if (!columnNames.contains('avatar_text')) {
      await db.execute('ALTER TABLE assets ADD COLUMN avatar_text TEXT');
    }

    if (!columnNames.contains('avatar_icon_code_point')) {
      await db.execute(
        'ALTER TABLE assets ADD COLUMN avatar_icon_code_point INTEGER',
      );
    }

    log('========== [LocalDb] V3.0 头像引擎字段升级完成 ==========');
  }

  static Future<Set<String>> _assetColumnNames(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(assets)');
    return columns.map((c) => c['name'] as String).toSet();
  }
}
