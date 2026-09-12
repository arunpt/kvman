import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/core/api/api_client.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/billing/billing_model.dart';
import 'package:kvman/features/billing/billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BillingRepository(dio);
});

// A provider for the raw, unfiltered transaction history
final transactionHistoryProvider = FutureProvider<List<TransactionItem>>((
  ref,
) async {
  final repo = ref.watch(billingRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final username = authState.activeUser?.userName;

  if (username == null) {
    throw Exception('No active user found');
  }

  return repo.getTransactionHistory(username);
});

enum TransactionDateRange { threeMonths, sixMonths, oneYear, allTime }

class TransactionFilterRangeNotifier extends Notifier<TransactionDateRange> {
  @override
  TransactionDateRange build() => TransactionDateRange.allTime;

  void setRange(TransactionDateRange range) {
    state = range;
  }
}

final transactionFilterRangeProvider =
    NotifierProvider<TransactionFilterRangeNotifier, TransactionDateRange>(
      TransactionFilterRangeNotifier.new,
    );

final filteredTransactionHistoryProvider =
    Provider<AsyncValue<List<TransactionItem>>>((ref) {
      final asyncTransactions = ref.watch(transactionHistoryProvider);
      final filterRange = ref.watch(transactionFilterRangeProvider);

      return asyncTransactions.whenData((transactions) {
        if (filterRange == TransactionDateRange.allTime) return transactions;

        final now = DateTime.now();
        DateTime cutoff;
        switch (filterRange) {
          case TransactionDateRange.threeMonths:
            cutoff = DateTime(now.year, now.month - 3, now.day);
            break;
          case TransactionDateRange.sixMonths:
            cutoff = DateTime(now.year, now.month - 6, now.day);
            break;
          case TransactionDateRange.oneYear:
            cutoff = DateTime(now.year - 1, now.month, now.day);
            break;
          case TransactionDateRange.allTime:
            return transactions;
        }

        return transactions.where((t) {
          if (t.purchaseDate == null) return false;
          return t.purchaseDate!.isAfter(cutoff);
        }).toList();
      });
    });

// --- Plan History Providers ---

final planHistoryProvider = FutureProvider<List<PlanHistoryItem>>((ref) async {
  final repo = ref.watch(billingRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final username = authState.activeUser?.userName;

  if (username == null) {
    throw Exception('No active user found');
  }

  return repo.getPlanHistory(username);
});
