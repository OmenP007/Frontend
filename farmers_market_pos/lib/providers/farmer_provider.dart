import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// ── Farmer search ─────────────────────────────────────────────────────────
class FarmerSearchState {
  final List<FarmerModel> farmers;
  final bool isLoading;
  final String? error;

  const FarmerSearchState({this.farmers = const [], this.isLoading = false, this.error});
}

class FarmerSearchNotifier extends StateNotifier<FarmerSearchState> {
  final ApiService _api;

  FarmerSearchNotifier(this._api) : super(const FarmerSearchState());

  Future<void> search(String query) async {
    state = const FarmerSearchState(isLoading: true);
    try {
      final res  = await _api.getFarmers(query: query.isEmpty ? null : query);
      final data = (res['data'] as List<dynamic>)
          .map((e) => FarmerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = FarmerSearchState(farmers: data);
    } catch (e) {
      state = FarmerSearchState(error: e.toString());
    }
  }

  Future<void> loadAll() => search('');

  void clear() => state = const FarmerSearchState();
}

final farmerSearchProvider =
    StateNotifierProvider<FarmerSearchNotifier, FarmerSearchState>((ref) {
  return FarmerSearchNotifier(ref.watch(apiServiceProvider));
});

// ── Selected farmer ───────────────────────────────────────────────────────
final selectedFarmerProvider = StateProvider<FarmerModel?>((ref) => null);

// ── Farmer detail (debts + credit summary) ────────────────────────────────
class FarmerDetailState {
  final FarmerModel? farmer;
  final double totalDebt;
  final double availableCredit;
  final List<DebtModel> debts;
  final bool isLoading;
  final String? error;

  const FarmerDetailState({
    this.farmer,
    this.totalDebt      = 0,
    this.availableCredit = 0,
    this.debts          = const [],
    this.isLoading      = false,
    this.error,
  });
}

class FarmerDetailNotifier extends StateNotifier<FarmerDetailState> {
  final ApiService _api;

  FarmerDetailNotifier(this._api) : super(const FarmerDetailState());

  Future<void> load(int farmerId) async {
    state = const FarmerDetailState(isLoading: true);
    try {
      final farmerRes = await _api.getFarmer(farmerId);
      final debtRes   = await _api.getFarmerDebts(farmerId);

      final farmer = FarmerModel.fromJson(farmerRes['farmer'] as Map<String, dynamic>);
      final debts  = (debtRes['debts'] as List<dynamic>)
          .map((d) => DebtModel.fromJson(d as Map<String, dynamic>))
          .toList();

      state = FarmerDetailState(
        farmer:         farmer,
        totalDebt:      (farmerRes['total_debt_fcfa']       as num).toDouble(),
        availableCredit:(farmerRes['available_credit_fcfa']  as num).toDouble(),
        debts:          debts,
      );
    } catch (e) {
      state = FarmerDetailState(error: e.toString());
    }
  }
}

final farmerDetailProvider =
    StateNotifierProvider<FarmerDetailNotifier, FarmerDetailState>((ref) {
  return FarmerDetailNotifier(ref.watch(apiServiceProvider));
});
