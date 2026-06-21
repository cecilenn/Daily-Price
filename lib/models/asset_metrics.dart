part of 'asset.dart';

extension AssetMetrics on Asset {
  /// 是否已卖出或退役
  bool get isSoldOrRetired => status == 1 || status == 2;

  /// 是否服役中
  bool get isActive => status == 0;

  /// 是否订阅资产
  bool get isSubscription => ownershipType == 'subscription';

  /// 订阅资产的当前到期日（最后一次续费到期日，无续费时按购买+预计寿命推算）
  int? get currentExpireDate {
    if (renewals.isNotEmpty) return renewals.last.expireDate;
    // 无续费记录时，用购买日期 + 预计寿命天数 计算
    if (expectedLifespanDays != null) {
      return purchaseDate + Duration(days: expectedLifespanDays!).inMilliseconds;
    }
    return null;
  }

  /// 订阅资产的剩余天数
  int get subscriptionRemainingDays {
    final expire = currentExpireDate;
    if (expire == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((expire - now) ~/ Duration.millisecondsPerDay).clamp(0, 99999);
  }

  /// 订阅资产的总续费金额
  double get totalRenewalCost => renewals.fold(0.0, (sum, r) => sum + r.price);

  /// 订阅资产的总实际订阅天数
  int get totalSubscribedDays =>
      renewals.fold(0, (sum, r) => sum + r.durationDays);

  /// 计算实际/冻结天数
  int get calculatedDays {
    final start = DateTime.fromMillisecondsSinceEpoch(purchaseDate);
    final end = (status == 1 || status == 2) && soldDate != null
        ? DateTime.fromMillisecondsSinceEpoch(soldDate!)
        : DateTime.now();
    final days = end.difference(start).inDays;
    return days > 0 ? days : 1;
  }

  /// 计算日均价格（核心业务逻辑）
  double get dailyCost {
    var cost = purchasePrice ?? 0;

    if (isSubscription && renewals.isNotEmpty) {
      cost = totalRenewalCost;
      final days = totalSubscribedDays;
      if (days > 0) return (cost / days) + consumableDailyCost;
      return 0;
    }

    if (status == 2 && soldPrice != null) {
      cost = (purchasePrice ?? 0) - soldPrice!;
    }

    final daysUsed = calculatedDays;
    if (status == 0 &&
        expectedLifespanDays != null &&
        expectedLifespanDays! > 0 &&
        daysUsed < expectedLifespanDays!) {
      return (cost / expectedLifespanDays!) + consumableDailyCost;
    }

    if (daysUsed <= 0) return cost;
    return (cost / daysUsed) + consumableDailyCost;
  }

  /// 计算剩余天数
  int? get remainingDays {
    final lifespan = expectedLifespanDays;
    if (lifespan == null) return null;
    final endDate = purchaseDate + Duration(days: lifespan).inMilliseconds;
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = (endDate - now) ~/ Duration.millisecondsPerDay;
    return difference > 0 ? difference : 0;
  }

  /// 计算已使用天数
  int get usedDays {
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = (now - purchaseDate) ~/ Duration.millisecondsPerDay;
    return difference > 0 ? difference : 0;
  }

  /// 计算实际使用天数（如果已卖出/退役，则计算到卖出/退役日期）
  int get actualUsedDays {
    if (soldDate != null) {
      final difference =
          (soldDate! - purchaseDate) ~/ Duration.millisecondsPerDay;
      return difference > 0 ? difference : 0;
    }
    return usedDays;
  }

  /// 是否已过期
  bool get isExpired {
    final remaining = remainingDays;
    return remaining == null || remaining == 0;
  }

  /// 计算实际日均花费（考虑卖出）
  double? get actualDailyCost {
    final price = purchasePrice;
    final sold = soldPrice;
    final date = soldDate;
    if (price == null || sold == null || date == null) return null;
    final days = (date - purchaseDate) ~/ Duration.millisecondsPerDay;
    if (days <= 0) return null;
    return (price - sold) / days;
  }

  /// 是否有耗材
  bool get hasConsumables => consumables.isNotEmpty;

  /// 所有耗材的日均成本之和
  double get consumableDailyCost {
    if (consumables.isEmpty) return 0;
    return consumables.fold(0.0, (sum, consumable) {
      final records = replacements
          .where((record) => record.consumableName == consumable.name)
          .toList();
      var avgPrice = consumable.price;
      if (records.isNotEmpty) {
        avgPrice =
            records.fold(0.0, (sum, record) => sum + record.price) /
            records.length;
      }
      final dailyCost = consumable.cycleDays > 0
          ? avgPrice / consumable.cycleDays
          : 0;
      return sum + dailyCost;
    });
  }

  /// 获取某个耗材距上次更换已过的天数
  int getConsumableDaysSinceReplacement(
    String consumableName,
    int purchasedAt,
  ) {
    final lastRecord = replacements
        .where((record) => record.consumableName == consumableName)
        .fold<ReplacementRecord?>(null, (latest, record) {
          if (latest == null || record.replacedAt > latest.replacedAt) {
            return record;
          }
          return latest;
        });
    final referenceTime = lastRecord?.replacedAt ?? purchasedAt;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now - referenceTime) / Duration.millisecondsPerDay).floor();
  }

  /// 获取某个耗材剩余天数（正数=剩余，负数=已过期）
  int getConsumableRemainingDays(ConsumableRecord consumable) {
    final usedDays = getConsumableDaysSinceReplacement(
      consumable.name,
      consumable.purchasedAt,
    );
    return consumable.cycleDays - usedDays;
  }

  /// 累计耗材总花费
  double get totalConsumableCost =>
      replacements.fold(0.0, (sum, record) => sum + record.price);

  /// 含耗材的日均成本 = (主体成本 + 累计耗材成本) / 使用天数
  double get dailyCostWithConsumables {
    final base = dailyCost;
    if (!hasConsumables) return base;
    final days = calculatedDays;
    if (days <= 0) return base;
    return (totalConsumableCost + (purchasePrice ?? 0)) / days;
  }
}
