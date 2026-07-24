import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/models/portfolio_transaction.dart';
import '../../data/repositories/portfolio_repository.dart';
import 'portfolio_state.dart';

class PortfolioCubit extends Cubit<PortfolioState> {
  final PortfolioRepository _repository;

  PortfolioCubit(this._repository) : super(PortfolioInitial());

  Future<void> fetchPortfolio() async {
    emit(PortfolioLoading());
    try {
      final user = SupabaseService.client?.auth.currentUser;
      if (user == null) {
        emit(PortfolioError('You must be logged in to view your portfolio.'));
        return;
      }

      final transactions = await _repository.getTransactions(user.id);
      
      // Calculate Summaries
      final Map<String, PortfolioSummary> summaries = {};
      for (var tx in transactions) {
        if (!summaries.containsKey(tx.fundId)) {
          summaries[tx.fundId] = PortfolioSummary(tx.fundId, tx.fundNameEn ?? 'Unknown Fund');
        }
        summaries[tx.fundId]!.totalUnits += tx.units;
        summaries[tx.fundId]!.totalCost += (tx.units * tx.purchasePrice);
      }

      emit(PortfolioLoaded(transactions, summaries));
    } catch (e) {
      emit(PortfolioError(e.toString()));
    }
  }

  Future<void> addTransaction(String fundId, double units, double price) async {
    try {
      final user = SupabaseService.client?.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final tx = PortfolioTransaction(
        userId: user.id,
        fundId: fundId,
        units: units,
        purchasePrice: price,
        transactionDate: DateTime.now(),
      );

      await _repository.addTransaction(tx);
      await fetchPortfolio(); // Refresh
    } catch (e) {
      emit(PortfolioError(e.toString()));
    }
  }
}
