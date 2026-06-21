import '../models/asset.dart';
import '../utils/asset_input_parser.dart';

class AssetFormSubmissionException implements Exception {
  final String message;

  const AssetFormSubmissionException(this.message);

  @override
  String toString() => message;
}

class AssetFormSubmission {
  final Asset? existingAsset;
  final String assetName;
  final String purchasePriceText;
  final String expectedDaysText;
  final int purchaseDate;
  final int isPinned;
  final int status;
  final double? soldPrice;
  final int? soldDate;
  final String category;
  final String ownershipType;
  final int? expireDate;
  final List<RenewalRecord> renewals;
  final List<ConsumableRecord> consumables;
  final List<ReplacementRecord> replacements;
  final List<String> tags;
  final int excludeFromTotal;
  final int excludeFromDaily;
  final String? avatarPath;
  final int? avatarBgColor;
  final String? avatarText;
  final int? avatarIconCodePoint;

  const AssetFormSubmission({
    required this.existingAsset,
    required this.assetName,
    required this.purchasePriceText,
    required this.expectedDaysText,
    required this.purchaseDate,
    required this.isPinned,
    required this.status,
    required this.soldPrice,
    required this.soldDate,
    required this.category,
    required this.ownershipType,
    required this.expireDate,
    required this.renewals,
    required this.consumables,
    required this.replacements,
    required this.tags,
    required this.excludeFromTotal,
    required this.excludeFromDaily,
    required this.avatarPath,
    required this.avatarBgColor,
    required this.avatarText,
    required this.avatarIconCodePoint,
  });
}

class AssetFormSubmissionService {
  const AssetFormSubmissionService._();

  static Asset buildAsset(AssetFormSubmission submission) {
    final price = double.tryParse(submission.purchasePriceText);
    if (price == null || price <= 0) {
      throw const AssetFormSubmissionException('请输入有效的购入价格');
    }

    int? expectedDays;
    if (submission.expectedDaysText.trim().isNotEmpty) {
      expectedDays = AssetInputParser.parseExpectedDays(
        submission.expectedDaysText,
      );
      if (expectedDays <= 0) {
        throw const AssetFormSubmissionException('请输入有效的预计使用时长');
      }
    }

    var calculatedExpireDate = submission.expireDate;
    if (submission.ownershipType == 'subscription' && expectedDays != null) {
      calculatedExpireDate =
          submission.purchaseDate + Duration(days: expectedDays).inMilliseconds;
    }

    return Asset.create(
      id: submission.existingAsset?.id,
      assetName: submission.assetName.trim(),
      purchasePrice: price,
      expectedLifespanDays: expectedDays,
      purchaseDate: submission.purchaseDate,
      isPinned: submission.isPinned,
      status: submission.status,
      soldPrice: submission.status == 2 ? submission.soldPrice : null,
      soldDate: submission.status == 1 || submission.status == 2
          ? submission.soldDate
          : null,
      category: submission.category,
      ownershipType: submission.ownershipType,
      expireDate: calculatedExpireDate,
      renewals: submission.renewals,
      consumables: submission.consumables,
      replacements: submission.replacements,
      tags: submission.tags,
      excludeFromTotal: submission.excludeFromTotal,
      excludeFromDaily: submission.excludeFromDaily,
      avatarPath: submission.avatarPath,
      avatarBgColor: submission.avatarBgColor,
      avatarText: submission.avatarText,
      avatarIconCodePoint: submission.avatarIconCodePoint,
    );
  }
}
