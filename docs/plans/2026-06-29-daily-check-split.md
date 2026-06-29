# Daily Check Split Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the inspection/checking domain out of Daily Price into a new Daily Check app, while simplifying Daily Price back to asset-cost management.

**Architecture:** Daily Price remains the personal asset/value app and removes both existing check modules. Daily Check is a separate Flutter app that can reuse selected Daily Price infrastructure, but its primary asset model becomes inspection-oriented: code, name, spec, department, user, location, note, and check state. Daily Check uses local SQLite plus WebDAV only; Supabase is intentionally out of scope for the first Daily Check release.

**Tech Stack:** Flutter, Provider, SQLite via `sqflite`, WebDAV via `http`, CSV import/export, QR generation/scanning, Code128 barcode generation/scanning.

---

## Current Decision

Daily Price and Daily Check should become two separate products.

Daily Price:
- Keeps personal asset tracking, price/lifespan/analysis, Supabase sync, local file import/export.
- Removes normal check and special inspection features.
- Does not need barcode export after the split.
- Still needs the compressed QR upgrade if full-asset QR sharing remains in Daily Price.

Daily Check:
- Keeps the "main asset list" concept, but the fields are inspection-oriented, not price-oriented.
- Keeps check/session workflows.
- Uses WebDAV for cloud asset library and check archive sync.
- Supports CSV, compressed QR, and Code128 barcode sharing.
- Does not use Supabase in the first version.
- Does not include price/cost analytics as a first-class concern.

## Non-Negotiable Boundaries

Do not keep check logic in Daily Price after the split. Keeping it "just in case" creates duplicated product direction and code drift.

Do not make Daily Check a low-code/custom-field product in the first version. Use fixed extension fields and hide empty values in UI.

Do not use asset UUIDs as printed asset codes. Use a visible `assetCode` field.

Do not silently overwrite cloud data. Any upload-overwrite flow must show a confirmation dialog.

## Daily Price Final Scope

Daily Price should be cleaned up before branching Daily Check.

Keep:
- Asset list, add/edit asset, detail page.
- Price, purchase date, lifecycle, status, category, ownership, tags.
- Supabase sync.
- Local file import/export.
- Analysis pages focused on value/cost/lifecycle.
- Full-asset QR sharing/import, upgraded to compressed versioned format.

Remove:
- Function hub "检查" entry.
- Function hub "特调检查" entry.
- `check_sessions` and `check_items` usage from active UI.
- `lib/features/inspection/**` from active routing.
- Check providers from app provider tree.
- Check scan/detail/list screens from navigation.

Decision still open:
- Whether to physically delete check files from Daily Price immediately, or first disconnect them from UI and delete after Daily Check is created.

Recommended answer:
- First disconnect from Daily Price UI and provider tree.
- Then create Daily Check branch/project from the current codebase.
- After Daily Check has copied the needed files, delete dead check files from Daily Price.

## Daily Check Product Scope

Daily Check should be an inspection-first app.

Primary asset fields:
- `assetCode`: user-visible unique code, Code128-safe.
- `assetName`: display name.
- `spec`: model/specification.
- `department`: owning department.
- `user`: responsible person or current user.
- `location`: physical location.
- `note`: optional notes.
- `status`: optional operational/check status.
- `category`: optional classification.
- `folderId`: optional single folder/asset package.

Fields intentionally excluded from first version:
- Purchase price.
- Daily cost.
- Lifespan depreciation.
- Consumables.
- Renewals.
- Replacement history.
- Supabase account sync.
- Fully custom user-defined fields.

## Asset Code Standard

Use Code128-safe uppercase identifiers:

```text
SW-001
NET-SW-001
OFFICE-PC-0001
```

Rules:
- Uppercase letters, digits, and `-` only.
- Recommended length: 4 to 32 characters.
- Unique inside one asset library.
- Do not reuse deleted codes.
- Avoid Chinese, spaces, `_`, `/`, and overly meaningful location/department encoding.

Reason:
- Code128 supports this cleanly.
- Humans can read and type it.
- Codes remain stable even if department/location/category changes.

## Sync Rules

Daily Price Supabase sync:
- Change to explicit two-way overwrite semantics only if Daily Price still needs this cleanup before split.
- Upload means local overwrites cloud.
- Download means cloud overwrites local.
- Both directions must show confirmation because either can destroy data.

Daily Check WebDAV sync:
- Upload asset library: local overwrites WebDAV asset library.
- Download asset library: WebDAV overwrites local asset library.
- Upload check archive/session: write check result to WebDAV.
- Download check archive/session: import from WebDAV.
- Every overwrite operation must show a confirmation dialog.
- Prefer writing a timestamped backup copy before overwriting remote JSON when feasible.

Important:
- The user has accepted overwrite semantics for simplicity.
- Do not implement "download only新增" in this plan.

## Sharing Formats

Daily Price:
- Full-asset QR only.
- No Code128 barcode export after split.
- QR should move from verbose JSON to compressed versioned payload.

Daily Check:
- CSV export/import.
- Full-asset compressed QR for asset transfer.
- Code128 label for physical stickers.

Code128 label layout:

```text
Asset display name
[Code128 barcode containing assetCode]
assetCode text
```

Special inspection/check sharing:
- Use Code128 labels only for physical assets.
- Scan result is the `assetCode`.
- App resolves `assetCode` against the local WebDAV-synced asset library.

## Compressed QR Format

Current Daily Price QR uses verbose JSON keys like:

```json
{
  "id": "...",
  "assetName": "...",
  "purchasePrice": 123,
  "purchaseDate": 1710000000000,
  "expectedLifespanDays": 365
}
```

New versioned compact format should be:

```json
{
  "v": 2,
  "t": "asset",
  "d": {
    "id": "...",
    "c": "SW-001",
    "n": "交换机",
    "cat": "网络设备",
    "st": 0,
    "loc": "机房A"
  }
}
```

Daily Price mapping:
- `id`: original asset id.
- `c`: asset code, if Daily Price keeps/gets this field.
- `n`: asset name.
- `p`: purchase price.
- `pd`: purchase date.
- `life`: expected lifespan days.
- `exp`: expire date.
- `st`: status.
- `cat`: category.
- `own`: ownership type.
- `tags`: tags.
- `pin`: is pinned.
- `xTotal`: exclude from total.
- `xDaily`: exclude from daily.
- `soldP`: sold price.
- `soldD`: sold date.

Daily Check mapping:
- `id`: optional local id.
- `c`: asset code.
- `n`: asset name.
- `spec`: spec.
- `dep`: department.
- `u`: user.
- `loc`: location.
- `note`: note.
- `st`: status.
- `cat`: category.
- `folder`: folder id or folder name, depending on final model.

Import parser requirements:
- Accept old verbose Daily Price JSON.
- Accept new v2 compact Daily Price JSON.
- Accept new v2 Daily Check JSON.
- Accept raw Code128/QR asset code for lookup flows.
- Reject unknown `t` types with a clear message.

Do not compress with gzip/base64 in the first pass. Short keys give most of the benefit while keeping payload debuggable.

## Daily Check Data Model

Recommended tables:

```sql
CREATE TABLE assets (
  id TEXT PRIMARY KEY,
  asset_code TEXT NOT NULL UNIQUE,
  asset_name TEXT NOT NULL,
  spec TEXT,
  department TEXT,
  user TEXT,
  location TEXT,
  note TEXT,
  status INTEGER DEFAULT 0,
  category TEXT,
  folder_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE folders (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  note TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE check_sessions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  status INTEGER DEFAULT 0
);

CREATE TABLE check_items (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  asset_code TEXT NOT NULL,
  asset_snapshot TEXT NOT NULL,
  confirmed_at INTEGER,
  FOREIGN KEY (session_id) REFERENCES check_sessions(id) ON DELETE CASCADE
);
```

Folder rule:
- One asset can belong to at most one folder.
- Folder card displays asset count.
- Folder behaves like an asset package, not a tag.

## Implementation Tasks

### Task 1: Freeze Current Daily Price Check Surface

**Files:**
- Inspect: `lib/screens/function_hub_screen.dart`
- Inspect: `lib/main.dart`
- Inspect: `lib/providers/check_provider.dart`
- Inspect: `lib/features/inspection/providers/inspection_provider.dart`

**Steps:**
1. List every UI entry that opens check or special inspection.
2. List every provider registered only for check features.
3. List every route/screen that becomes dead after removal.
4. Do not delete files yet.
5. Commit the documentation/update.

### Task 2: Upgrade Daily Price QR Format

**Files:**
- Modify: `lib/services/asset_share_service.dart`
- Modify: `lib/services/asset_qr_service.dart`
- Modify: `lib/services/asset_scan_import_service.dart`
- Modify: `lib/widgets/asset_qr_share_dialog.dart`
- Test: add or update QR parsing tests.

**Steps:**
1. Add serializer for v2 compact QR.
2. Keep legacy verbose serializer only if needed for backward compatibility tests.
3. Update parser to accept legacy verbose JSON and v2 compact JSON.
4. Add tests for legacy import.
5. Add tests for v2 import.
6. Verify existing scan/import UI still works.

### Task 3: Simplify Daily Price Check Features Out of Navigation

**Files:**
- Modify: `lib/screens/function_hub_screen.dart`
- Modify: `lib/main.dart`
- Potentially modify: tests referencing check providers.

**Steps:**
1. Remove "检查" card from active UI.
2. Remove "特调检查" card from active UI.
3. Remove unused check providers from provider tree after verifying no remaining references.
4. Run `flutter analyze`.
5. Run relevant widget tests.
6. Commit.

### Task 4: Create Daily Check Project From Daily Price Baseline

**Files:**
- Target folder: `/Users/liuzongpei/Projects/daily check`
- Source folder: `/Users/liuzongpei/Projects/daily price`

**Steps:**
1. Create a new branch or copy baseline into `daily check`.
2. Rename package/app display name to Daily Check.
3. Remove Daily Price-specific branding.
4. Remove Supabase setup from Daily Check.
5. Keep only WebDAV sync infrastructure.
6. Commit the initial Daily Check scaffold.

### Task 5: Convert Daily Check Asset Model

**Files:**
- Modify/create Daily Check asset model.
- Modify/create Daily Check SQLite schema.
- Modify add/edit asset screens.
- Modify asset cards and detail screens.

**Steps:**
1. Replace price-first fields with inspection-first fields.
2. Keep empty-field hiding in detail UI.
3. Add `assetCode` uniqueness validation.
4. Add batch creation: prefix, start number, width, separator, quantity.
5. Add folder assignment with one-folder-only rule.
6. Run migration tests or manual migration validation.

### Task 6: Daily Check WebDAV Asset Library

**Files:**
- Reuse/adapt: `lib/features/inspection/services/webdav_config.dart`
- Reuse/adapt: `lib/features/inspection/services/webdav_service.dart`
- Modify Daily Check settings screens.

**Steps:**
1. Add WebDAV config screen for Daily Check.
2. Implement asset library upload overwrite.
3. Implement asset library download overwrite.
4. Add confirmation dialogs for both directions.
5. Add WebDAV JSON parse validation.
6. Add backup-before-overwrite if practical.

### Task 7: Daily Check Check Sessions

**Files:**
- Reuse/adapt current normal check and special inspection screens.
- Consolidate duplicated check concepts.

**Steps:**
1. Choose one check flow, not two.
2. Use `assetCode` as the scan key.
3. On scan entry, look up local asset library by `assetCode`.
4. Store asset snapshots in check items.
5. On scan confirm, confirm existing check item.
6. Add archive upload/download via WebDAV.

### Task 8: Daily Check Sharing

**Files:**
- Create/adapt QR share service.
- Create/adapt Code128 label service/widget.
- Create/adapt CSV service.

**Steps:**
1. Implement CSV export/import for Daily Check fields.
2. Implement v2 compact QR export/import.
3. Implement Code128 label image generation.
4. Add batch actions: CSV, QR, barcode.
5. Add special inspection/check label sharing.

### Task 9: Daily Check Analysis Placeholder

**Files:**
- Modify Daily Check analysis screen.

**Steps:**
1. Remove price/cost analytics.
2. Add placeholders for future analysis:
   - asset count by status.
   - asset count by department.
   - asset count by location.
   - check completion rate.
   - missing/unconfirmed assets.
3. Keep UI simple and clearly marked as placeholder.

## Verification Plan

Daily Price:
- Run `flutter analyze`.
- Verify app opens.
- Verify asset add/edit still works.
- Verify full QR export/import still works with legacy and v2 compact payloads.
- Verify check entries are gone from active UI.
- Verify Supabase sync still compiles and runs if retained.

Daily Check:
- Run `flutter analyze`.
- Verify app opens under Daily Check name.
- Verify asset create/edit with `assetCode`.
- Verify duplicate `assetCode` is blocked.
- Verify CSV import/export.
- Verify Code128 label renders with name, barcode, and code.
- Verify scan resolves `assetCode`.
- Verify WebDAV upload overwrite shows confirmation.
- Verify WebDAV download overwrite shows confirmation.
- Verify offline local asset library still works after previous WebDAV download.

## Open Questions Before Coding

1. Daily Price should keep Supabase upload/download as current full-replace semantics, or should we also change its UI wording to "上传覆盖/下载覆盖" without changing deeper behavior?
2. Should Daily Price receive `assetCode`, or should `assetCode` exist only in Daily Check after the split?
3. Should Daily Price full QR v2 include all renewal/consumable/replacement history, or should it export only core asset fields?
4. Should Daily Check be created by copying the current Daily Price project, or by creating a fresh Flutter app and moving selected files in?
5. Should old check files be deleted from Daily Price before or after Daily Check proves it builds?

## Recommended Next Step

Before coding, decide Daily Price's final retained scope:

1. Keep Supabase full overwrite behavior but improve confirmation wording.
2. Upgrade full QR to compact v2 with legacy import compatibility.
3. Remove check and special inspection from Daily Price navigation.
4. Create Daily Check branch/project from the cleaned baseline.
5. Move check work into Daily Check.

