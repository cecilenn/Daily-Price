import 'package:daily_price/features/inspection/providers/inspection_provider.dart';
import 'package:daily_price/features/inspection/models/company_asset.dart';
import 'package:daily_price/features/inspection/models/company_check_item.dart';
import 'package:daily_price/models/asset.dart';
import 'package:daily_price/features/inspection/services/inspection_asset_code_parser.dart';
import 'package:daily_price/models/asset_category.dart';
import 'package:daily_price/providers/app_provider.dart';
import 'package:daily_price/providers/asset_provider.dart';
import 'package:daily_price/providers/check_provider.dart';
import 'package:daily_price/services/asset_analysis_service.dart';
import 'package:daily_price/services/asset_batch_service.dart';
import 'package:daily_price/services/asset_csv_service.dart';
import 'package:daily_price/services/asset_filter_sorter.dart';
import 'package:daily_price/services/asset_form_submission_service.dart';
import 'package:daily_price/services/asset_preferences_service.dart';
import 'package:daily_price/services/asset_qr_service.dart';
import 'package:daily_price/services/asset_scan_import_service.dart';
import 'package:daily_price/services/asset_share_service.dart';
import 'package:daily_price/services/check_asset_snapshot_service.dart';
import 'package:daily_price/services/check_session_archive_service.dart';
import 'package:daily_price/services/local_db_schema.dart';
import 'package:daily_price/utils/asset_input_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_price/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('keeps local database schema identity centralized', () {
    expect(LocalDbSchema.databaseName, 'daily_price.db');
    expect(LocalDbSchema.version, 9);
  });

  test(
    'upgrades legacy asset schema without losing category semantics',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);

      await db.execute('''
      CREATE TABLE assets(
        id TEXT PRIMARY KEY,
        asset_name TEXT NOT NULL,
        purchase_price REAL,
        purchase_date INTEGER NOT NULL,
        is_pinned INTEGER DEFAULT 0,
        category TEXT DEFAULT 'physical',
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
        exclude_from_daily INTEGER DEFAULT 0
      )
    ''');

      await db.insert('assets', {
        'id': 'subscription-asset',
        'asset_name': '视频会员',
        'purchase_date': 1767225600000,
        'category': 'subscription',
        'created_at': 1767225600000,
      });
      await db.insert('assets', {
        'id': 'physical-asset',
        'asset_name': '键盘',
        'purchase_date': 1767225600000,
        'category': 'physical',
        'created_at': 1767225600000,
      });
      await db.insert('assets', {
        'id': 'custom-asset',
        'asset_name': '咖啡机',
        'purchase_date': 1767225600000,
        'category': '家电',
        'created_at': 1767225600000,
      });

      await LocalDbSchema.upgrade(db, 5, LocalDbSchema.version);

      final columnNames = (await db.rawQuery(
        'PRAGMA table_info(assets)',
      )).map((column) => column['name']).toSet();
      expect(
        columnNames,
        containsAll([
          'ownership_type',
          'renewals',
          'consumables',
          'replacements',
        ]),
      );

      final rows = await db.query('assets', orderBy: 'id');
      final byId = {for (final row in rows) row['id'] as String: row};

      expect(
        byId['subscription-asset']?['category'],
        AssetCategory.uncategorized,
      );
      expect(byId['subscription-asset']?['ownership_type'], 'subscription');
      expect(byId['subscription-asset']?['renewals'], '[]');
      expect(byId['subscription-asset']?['consumables'], '[]');
      expect(byId['subscription-asset']?['replacements'], '[]');

      expect(byId['physical-asset']?['category'], AssetCategory.uncategorized);
      expect(byId['physical-asset']?['ownership_type'], 'buyout');
      expect(byId['custom-asset']?['category'], '家电');
      expect(byId['custom-asset']?['ownership_type'], 'buyout');

      final checkTables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('check_sessions', 'check_items')",
      );
      expect(checkTables.map((row) => row['name']).toSet(), {
        'check_sessions',
        'check_items',
      });
    },
  );

  test('normalizes legacy category values into the current model', () {
    final asset = Asset.create(
      assetName: '视频会员',
      purchaseDate: DateTime(2026).millisecondsSinceEpoch,
      category: 'subscription',
    );

    expect(asset.category, AssetCategory.uncategorized);
    expect(asset.ownershipType, 'subscription');
  });

  test('keeps asset input parsing compatible with legacy Asset helpers', () {
    expect(AssetInputParser.parseExpectedDays('1年6个月10天'), 555);
    expect(Asset.parseExpectedDays('1年6个月10天'), 555);

    final parsed = AssetInputParser.parseCustomDate('2026 年 4 月 5 日');
    final legacyParsed = Asset.parseCustomDate('2026 年 4 月 5 日');

    expect(parsed, DateTime(2026, 4, 5));
    expect(legacyParsed, DateTime(2026, 4, 5));
    expect(AssetInputParser.formatDays(395), '1 年1 月');
    expect(Asset.formatDays(395), '1 年1 月');
  });

  test(
    'builds submitted assets with normalized category and subscription date',
    () {
      final asset = AssetFormSubmissionService.buildAsset(
        const AssetFormSubmission(
          existingAsset: null,
          assetName: ' 视频会员 ',
          purchasePriceText: '120',
          expectedDaysText: '1年',
          purchaseDate: 1767225600000,
          isPinned: 0,
          status: 0,
          soldPrice: null,
          soldDate: null,
          category: 'subscription',
          ownershipType: 'subscription',
          expireDate: null,
          renewals: [],
          consumables: [],
          replacements: [],
          tags: [],
          excludeFromTotal: 0,
          excludeFromDaily: 0,
          avatarPath: null,
          avatarBgColor: null,
          avatarText: null,
          avatarIconCodePoint: null,
        ),
      );

      expect(asset.assetName, '视频会员');
      expect(asset.category, AssetCategory.uncategorized);
      expect(asset.ownershipType, 'subscription');
      expect(asset.expectedLifespanDays, 365);
      expect(
        asset.expireDate,
        1767225600000 + Duration(days: 365).inMilliseconds,
      );
    },
  );

  test('preserves submitted asset records and avatar fields', () {
    final asset = AssetFormSubmissionService.buildAsset(
      const AssetFormSubmission(
        existingAsset: null,
        assetName: '净水器',
        purchasePriceText: '1000',
        expectedDaysText: '',
        purchaseDate: 1767225600000,
        isPinned: 0,
        status: 0,
        soldPrice: null,
        soldDate: null,
        category: '家电',
        ownershipType: 'buyout',
        expireDate: null,
        renewals: [
          RenewalRecord(
            id: 'renewal-1',
            renewalDate: 1767225600000,
            price: 120,
            durationDays: 365,
          ),
        ],
        consumables: [
          ConsumableRecord(
            id: 'filter',
            name: '滤芯',
            price: 99,
            cycleDays: 180,
            purchasedAt: 1767225600000,
            updatedAt: 1767225600000,
          ),
        ],
        replacements: [
          ReplacementRecord(
            id: 'replacement-1',
            consumableName: '滤芯',
            replacedAt: 1767225600000,
            price: 99,
          ),
        ],
        tags: ['custom_home'],
        excludeFromTotal: 1,
        excludeFromDaily: 1,
        avatarPath: '/tmp/avatar.png',
        avatarBgColor: 0xFF2196F3,
        avatarText: '净',
        avatarIconCodePoint: 0xe8b8,
      ),
    );

    expect(asset.renewals.single.id, 'renewal-1');
    expect(asset.consumables.single.name, '滤芯');
    expect(asset.replacements.single.id, 'replacement-1');
    expect(asset.tags, ['custom_home']);
    expect(asset.excludeFromTotal, 1);
    expect(asset.excludeFromDaily, 1);
    expect(asset.avatarPath, '/tmp/avatar.png');
    expect(asset.avatarBgColor, 0xFF2196F3);
    expect(asset.avatarText, '净');
    expect(asset.avatarIconCodePoint, 0xe8b8);
  });

  test('rejects invalid submitted asset duration', () {
    expect(
      () => AssetFormSubmissionService.buildAsset(
        const AssetFormSubmission(
          existingAsset: null,
          assetName: '设备',
          purchasePriceText: '100',
          expectedDaysText: '随缘',
          purchaseDate: 1767225600000,
          isPinned: 0,
          status: 0,
          soldPrice: null,
          soldDate: null,
          category: '数码',
          ownershipType: 'buyout',
          expireDate: null,
          renewals: [],
          consumables: [],
          replacements: [],
          tags: [],
          excludeFromTotal: 0,
          excludeFromDaily: 0,
          avatarPath: null,
          avatarBgColor: null,
          avatarText: null,
          avatarIconCodePoint: null,
        ),
      ),
      throwsA(isA<AssetFormSubmissionException>()),
    );
  });

  test('normalizes stored category preferences', () async {
    SharedPreferences.setMockInitialValues({
      AssetPreferencesService.customCategoriesKey: [
        'physical',
        '数码',
        'subscription',
        '数码',
      ],
      AssetPreferencesService.homeCurrentCategoryKey: 'virtual',
      AssetPreferencesService.defaultStartupCategoryKey: 'subscription',
    });

    final categories = await AssetPreferencesService.loadCustomCategories();
    final homePreferences = await AssetPreferencesService.loadHomePreferences();
    final defaultCategory =
        await AssetPreferencesService.loadDefaultStartupCategory();
    final prefs = await SharedPreferences.getInstance();

    expect(categories, [AssetCategory.uncategorized, '数码']);
    expect(homePreferences.currentCategory, AssetCategory.uncategorized);
    expect(defaultCategory, AssetCategory.uncategorized);
    expect(prefs.getStringList(AssetPreferencesService.customCategoriesKey), [
      AssetCategory.uncategorized,
      '数码',
    ]);
    expect(
      prefs.getString(AssetPreferencesService.homeCurrentCategoryKey),
      AssetCategory.uncategorized,
    );
    expect(
      prefs.getString(AssetPreferencesService.defaultStartupCategoryKey),
      AssetCategory.uncategorized,
    );
  });

  test('parses CSV exports with current asset fields', () {
    final source = Asset.create(
      id: 'asset-1',
      assetName: '视频会员',
      purchasePrice: 120,
      purchaseDate: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      category: 'subscription',
      ownershipType: 'subscription',
      tags: ['custom_media'],
      renewals: const [
        RenewalRecord(
          id: 'renewal-1',
          renewalDate: 1767225600000,
          price: 120,
          durationDays: 365,
        ),
      ],
    );

    final csv = AssetCsvService.encode([source]);
    final parsed = AssetCsvService.parse(csv);

    expect(parsed.skippedRows, 0);
    expect(parsed.assets, hasLength(1));
    expect(parsed.assets.single.assetName, '视频会员');
    expect(parsed.assets.single.category, AssetCategory.uncategorized);
    expect(parsed.assets.single.ownershipType, 'subscription');
    expect(parsed.assets.single.tags, ['custom_media']);
    expect(parsed.assets.single.renewals, hasLength(1));
  });

  test('parses LF-only asset CSV input', () {
    final parsed = AssetCsvService.parse('''
asset_name,purchase_price,purchase_date,category
键盘,199,1767225600000,physical
''');

    expect(parsed.skippedRows, 0);
    expect(parsed.assets, hasLength(1));
    expect(parsed.assets.single.assetName, '键盘');
    expect(parsed.assets.single.category, AssetCategory.uncategorized);
  });

  test('parses timestamp dates and numeric boolean CSV fields', () {
    final parsed = AssetCsvService.parse('''
asset_name,purchase_price,purchase_date,is_pinned,exclude_from_total,exclude_from_daily
键盘,199,1767225600000,1,true,yes
''');

    final asset = parsed.assets.single;

    expect(asset.purchaseDate, 1767225600000);
    expect(asset.isPinned, 1);
    expect(asset.excludeFromTotal, 1);
    expect(asset.excludeFromDaily, 1);
  });

  test('parses asset QR payloads without preserving legacy categories', () {
    final parsed = AssetQrService.parse('''
      {
        "id": "asset-qr-1",
        "assetName": "云服务",
        "purchasePrice": 99,
        "purchaseDate": 1767225600000,
        "category": "subscription"
      }
    ''');

    expect(parsed.originalId, 'asset-qr-1');
    expect(parsed.asset.category, AssetCategory.uncategorized);
    expect(parsed.asset.ownershipType, 'subscription');
    expect(parsed.asset.avatarPath, isNull);
  });

  test('roundtrips shared subscription QR data without losing ownership', () {
    final source = Asset.create(
      id: 'shared-subscription',
      assetName: '云服务',
      purchasePrice: 99,
      purchaseDate: 1767225600000,
      category: '软件',
      ownershipType: 'subscription',
      expectedLifespanDays: 365,
      expireDate: 1798761600000,
      renewals: const [
        RenewalRecord(
          id: 'renewal-1',
          renewalDate: 1767225600000,
          price: 99,
          durationDays: 365,
        ),
      ],
    );

    final parsed = AssetQrService.parse(
      AssetShareService.serializeToQrJson(source),
    );

    expect(parsed.asset.category, '软件');
    expect(parsed.asset.ownershipType, 'subscription');
    expect(parsed.asset.expireDate, 1798761600000);
    expect(parsed.asset.renewals.single.id, 'renewal-1');
  });

  test('parses stringly typed QR numeric and boolean fields', () {
    final parsed = AssetQrService.parse('''
      {
        "id": 123,
        "assetName": "字符串字段设备",
        "purchasePrice": "88.5",
        "purchaseDate": "1767225600000",
        "isPinned": "true",
        "excludeFromTotal": "1",
        "excludeFromDaily": "yes"
      }
    ''');

    expect(parsed.originalId, '123');
    expect(parsed.asset.purchasePrice, 88.5);
    expect(parsed.asset.purchaseDate, 1767225600000);
    expect(parsed.asset.isPinned, 1);
    expect(parsed.asset.excludeFromTotal, 1);
    expect(parsed.asset.excludeFromDaily, 1);
  });

  test('builds check snapshots from scanned QR with normalized categories', () {
    final snapshot = CheckAssetSnapshotService.fromScannedValue('''
      {
        "id": "asset-scan-1",
        "assetName": "旧分类设备",
        "purchasePrice": 300,
        "purchaseDate": 1767225600000,
        "category": "virtual",
        "status": 0
      }
    ''');

    expect(snapshot.assetId, 'asset-scan-1');
    expect(snapshot.data['assetName'], '旧分类设备');
    expect(snapshot.data['category'], AssetCategory.uncategorized);
  });

  test('resolves scanned asset QR into existing or preview actions', () async {
    final existing = Asset.create(
      id: 'asset-existing',
      assetName: '已有资产',
      purchaseDate: 1767225600000,
      category: '数码',
    );

    final existingResult = await AssetScanImportService.resolve(
      qrData: '''
        {
          "id": "asset-existing",
          "assetName": "二维码资产",
          "purchaseDate": 1767225600000,
          "category": "physical"
        }
      ''',
      findExistingById: (id) async => id == existing.id ? existing : null,
    );
    final previewResult = await AssetScanImportService.resolve(
      qrData: '''
        {
          "id": "asset-new",
          "assetName": "新资产",
          "purchaseDate": 1767225600000,
          "category": "virtual"
        }
      ''',
      findExistingById: (_) async => null,
    );

    expect(existingResult.action, AssetScanImportAction.showExisting);
    expect(existingResult.asset.assetName, '已有资产');
    expect(previewResult.action, AssetScanImportAction.previewNew);
    expect(previewResult.asset.category, AssetCategory.uncategorized);
  });

  test('prepares batch share payload from selected assets only', () {
    final assets = [
      Asset.create(
        id: 'a1',
        assetName: '键盘',
        purchasePrice: 199,
        purchaseDate: 1767225600000,
        category: '数码',
      ),
      Asset.create(
        id: 'a2',
        assetName: '鼠标',
        purchasePrice: 99,
        purchaseDate: 1767225600000,
        category: '数码',
      ),
    ];

    final payload = AssetBatchService.prepareSharePayload(assets, [
      'a2',
    ], timestamp: 123);
    final emptyPayload = AssetBatchService.prepareSharePayload(assets, [
      'missing',
    ], timestamp: 123);

    expect(payload, isNotNull);
    expect(payload!.defaultFileName, 'daily_price_selected_123.csv');
    expect(payload.assetCount, 1);
    expect(payload.csvString, contains('鼠标'));
    expect(payload.csvString, isNot(contains('键盘')));
    expect(emptyPayload, isNull);
  });

  test('filters assets using consolidated filter state', () {
    final assets = [
      Asset.create(
        id: 'active-camera',
        assetName: '相机',
        purchasePrice: 5000,
        purchaseDate: 1767225600000,
        category: '数码',
        tags: ['custom_work'],
        status: 0,
      ),
      Asset.create(
        id: 'retired-camera',
        assetName: '旧相机',
        purchasePrice: 1000,
        purchaseDate: 1767225600000,
        category: '数码',
        tags: ['custom_work'],
        status: 1,
      ),
      Asset.create(
        id: 'active-chair',
        assetName: '椅子',
        purchasePrice: 300,
        purchaseDate: 1767225600000,
        category: '家具',
        tags: ['custom_home'],
        status: 0,
      ),
    ];

    final filtered = AssetFilterSorter.filterAndSort(
      assets: assets,
      category: 'all',
      sortBy: 'created_at',
      ascending: true,
      filterState: const AssetFilterState(
        statusFilter: 0,
        selectedCategories: {'数码'},
        selectedTags: {'custom_work'},
      ),
    );

    expect(filtered.map((asset) => asset.id), ['active-camera']);
  });

  test('calculates analysis using exclusion flags consistently', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final included = Asset.create(
      id: 'included',
      assetName: '主力设备',
      purchasePrice: 100,
      purchaseDate: now,
      category: '数码',
      expectedLifespanDays: 100,
    );
    final excluded = Asset.create(
      id: 'excluded',
      assetName: '排除项',
      purchasePrice: 10000,
      purchaseDate: now,
      category: '数码',
      expectedLifespanDays: 10,
      excludeFromTotal: 1,
      excludeFromDaily: 1,
    );

    final analysis = AssetAnalysisService.calculate([included, excluded]);

    expect(analysis.overview.totalAssets, 100);
    expect(analysis.overview.averagePerItem, 100);
    expect(analysis.categoryBreakdown, hasLength(1));
    expect(analysis.categoryBreakdown.single.category, '数码');
    expect(analysis.categoryBreakdown.single.count, 1);
    expect(analysis.categoryBreakdown.single.value, 100);
    expect(analysis.dailyCostTopAssets.map((a) => a.id), ['included']);
  });

  test('parses compact check-session CSV exports without optional columns', () {
    final sessions = CheckSessionArchiveService.parseCsv('''
session_id,session_name,asset_id
s1,季度盘点,a1
''');

    expect(sessions, hasLength(1));
    expect(sessions.single.name, '季度盘点');
    expect(sessions.single.items, hasLength(1));
    expect(sessions.single.items.single.assetId, 'a1');
    expect(sessions.single.items.single.snapshot['category'], '未分类');
    expect(sessions.single.items.single.isConfirmed, isFalse);
  });

  test('encodes check-session export data with normalized categories', () {
    final csv = CheckSessionArchiveService.encodeExportData({
      'session': {
        'id': 's1',
        'name': '盘点',
        'status': 0,
        'created_at': 1767225600000,
      },
      'items': [
        {
          'id': 'i1',
          'asset_id': 'a1',
          'asset_snapshot':
              '{"assetName":"设备","purchasePrice":88,"category":"physical","status":0}',
          'confirmed_at': null,
        },
      ],
    });

    final parsed = CheckSessionArchiveService.parseCsv(csv);

    expect(parsed, hasLength(1));
    expect(parsed.single.items.single.snapshot['category'], '未分类');
  });

  test(
    'keeps inspection item snapshots safe when stored data is malformed',
    () {
      final invalid = CompanyCheckItem(
        id: 'item-1',
        sessionId: 'session-1',
        assetCode: 'EQ-001',
        assetSnapshot: 'not-json',
      );
      final numericName = CompanyCheckItem(
        id: 'item-2',
        sessionId: 'session-1',
        assetCode: 'EQ-002',
        assetSnapshot: '{"asset_name": 123}',
      );

      expect(invalid.snapshotData['assetCode'], 'EQ-001');
      expect(invalid.assetName, '未知资产');
      expect(numericName.assetName, '123');
    },
  );

  test('parses company assets from Chinese or English WebDAV fields', () {
    final chinese = CompanyAsset.fromJson({
      '资产编码': 'CN-001',
      '资产名称': '展台',
      '规格型号': 'A1',
      '使用部门': '市场',
      '使用人': '张三',
      '存放位置': '上海',
    });
    final english = CompanyAsset.fromJson({
      'asset_code': 'EN-001',
      'asset_name': 'Booth',
      'spec': 'B1',
      'department': 'Marketing',
      'owner': 'Alice',
      'location': 'Beijing',
    });

    expect(chinese.assetCode, 'CN-001');
    expect(chinese.assetName, '展台');
    expect(english.assetCode, 'EN-001');
    expect(english.assetName, 'Booth');
    expect(english.user, 'Alice');
  });

  test('parses inspection scan asset codes without creating null codes', () {
    expect(InspectionAssetCodeParser.parse(' EQ-001 '), 'EQ-001');
    expect(InspectionAssetCodeParser.parse('{"资产编码":"CN-001"}'), 'CN-001');
    expect(
      InspectionAssetCodeParser.parse('{"asset_code":"EN-001"}'),
      'EN-001',
    );
    expect(InspectionAssetCodeParser.parse('{"code": 123}'), '123');
    expect(InspectionAssetCodeParser.parse('{}'), isNull);
    expect(InspectionAssetCodeParser.parse(''), isNull);
  });

  testWidgets('Home screen renders inside the real provider tree', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => AssetProvider()),
          ChangeNotifierProvider(create: (_) => CheckProvider()),
          ChangeNotifierProvider(create: (_) => InspectionProvider()),
        ],
        child: const DailyPriceApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('资产'), findsOneWidget);
    expect(find.text('功能'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('暂无资产数据'), findsOneWidget);
  });
}
