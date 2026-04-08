import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/company_asset.dart';
import '../models/company_check_session.dart';
import '../models/company_check_item.dart';

class InspectionDb {
  static final InspectionDb _instance = InspectionDb._internal();
  factory InspectionDb() => _instance;
  InspectionDb._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inspection.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE company_assets (
            asset_code TEXT PRIMARY KEY,
            asset_name TEXT NOT NULL DEFAULT '',
            spec TEXT NOT NULL DEFAULT '',
            department TEXT NOT NULL DEFAULT '',
            user TEXT NOT NULL DEFAULT '',
            location TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE company_check_sessions (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            status INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE company_check_items (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            asset_code TEXT NOT NULL,
            asset_snapshot TEXT NOT NULL,
            confirmed_at INTEGER,
            FOREIGN KEY (session_id) REFERENCES company_check_sessions(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _db!;
  }

  // ==================== Company Assets ====================

  Future<void> replaceAllAssets(List<CompanyAsset> assets) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('company_assets');
      for (final asset in assets) {
        await txn.insert('company_assets', asset.toMap());
      }
    });
  }

  Future<CompanyAsset?> getAssetByCode(String assetCode) async {
    final db = await database;
    final maps = await db.query(
      'company_assets',
      where: 'asset_code = ?',
      whereArgs: [assetCode],
    );
    if (maps.isEmpty) return null;
    return CompanyAsset.fromMap(maps.first);
  }

  Future<int> getAssetCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM company_assets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<CompanyAsset>> getAllAssets() async {
    final db = await database;
    final maps = await db.query('company_assets', orderBy: 'asset_code');
    return maps.map((m) => CompanyAsset.fromMap(m)).toList();
  }

  Future<void> insertOrUpdateAsset(CompanyAsset asset) async {
    final db = await database;
    await db.insert(
      'company_assets',
      asset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAsset(String assetCode) async {
    final db = await database;
    await db.delete(
      'company_assets',
      where: 'asset_code = ?',
      whereArgs: [assetCode],
    );
  }

  // ==================== Check Sessions ====================

  Future<void> insertSession(CompanyCheckSession session) async {
    final db = await database;
    await db.insert('company_check_sessions', session.toMap());
  }

  Future<List<CompanyCheckSession>> getAllSessions() async {
    final db = await database;
    final maps = await db.query(
      'company_check_sessions',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => CompanyCheckSession.fromMap(m)).toList();
  }

  Future<CompanyCheckSession?> getSession(String id) async {
    final db = await database;
    final maps = await db.query(
      'company_check_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CompanyCheckSession.fromMap(maps.first);
  }

  Future<void> updateSessionStatus(String id, int status) async {
    final db = await database;
    await db.update(
      'company_check_sessions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSessionName(String id, String name) async {
    final db = await database;
    await db.update(
      'company_check_sessions',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'company_check_items',
      where: 'session_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'company_check_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Check Items ====================

  Future<void> insertItem(CompanyCheckItem item) async {
    final db = await database;
    await db.insert('company_check_items', item.toMap());
  }

  Future<List<CompanyCheckItem>> getItems(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'company_check_items',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return maps.map((m) => CompanyCheckItem.fromMap(m)).toList();
  }

  Future<void> confirmItem(String id) async {
    final db = await database;
    await db.update(
      'company_check_items',
      {'confirmed_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> unconfirmItem(String id) async {
    final db = await database;
    await db.update(
      'company_check_items',
      {'confirmed_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('company_check_items', where: 'id = ?', whereArgs: [id]);
  }
}
