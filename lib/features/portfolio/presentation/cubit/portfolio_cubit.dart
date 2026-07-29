import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/portfolio_item_model.dart';
import '../../data/repositories/portfolio_repository.dart';
import 'portfolio_state.dart';

class PortfolioCubit extends Cubit<PortfolioState> {
  final PortfolioRepository repository;

  PortfolioCubit({required this.repository}) : super(PortfolioInitial());

  Future<void> loadPortfolio() async {
    emit(PortfolioLoading());
    try {
      // Safely try to refresh NAVs from Supabase with non-blocking error handling
      try {
        await repository.refreshPortfolioNavs().timeout(const Duration(seconds: 4));
      } catch (_) {}

      final portfolios = await repository.getAllPortfolios();
      final activeId = await repository.getActivePortfolioId();

      final activePortfolio = portfolios.firstWhere(
        (p) => p.id == activeId,
        orElse: () => portfolios.first,
      );

      final health = repository.calculatePortfolioHealth(activePortfolio.items);

      emit(PortfolioLoaded(
        allPortfolios: portfolios,
        activePortfolio: activePortfolio,
        items: activePortfolio.items,
        healthSummary: health,
      ));
    } catch (e) {
      emit(PortfolioError(message: 'تعذر تحميل المحفظة: ${e.toString()}'));
    }
  }

  Future<void> createPortfolio(String name) async {
    if (name.trim().isEmpty) return;
    await repository.createPortfolio(name.trim());
    await loadPortfolio();
  }

  Future<void> switchPortfolio(String portfolioId) async {
    await repository.setActivePortfolioId(portfolioId);
    await loadPortfolio();
  }

  Future<void> deletePortfolio(String portfolioId) async {
    await repository.deletePortfolio(portfolioId);
    await loadPortfolio();
  }

  Future<void> addTransaction({
    required String fundName,
    required FundCategory category,
    required double units,
    required double purchasePrice,
    required double currentNav,
  }) async {
    final newItem = PortfolioItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fundId: 'fund-${DateTime.now().millisecondsSinceEpoch}',
      fundName: fundName,
      category: category,
      units: units,
      purchasePrice: purchasePrice,
      currentNav: currentNav,
      purchaseDate: DateTime.now(),
    );

    await repository.addTransactionToActive(newItem);
    await loadPortfolio();
  }

  Future<void> removeTransaction(String id) async {
    await repository.removeTransactionFromActive(id);
    await loadPortfolio();
  }

  Future<void> updateTransactionUnits({
    required String itemId,
    required double newUnits,
  }) async {
    await repository.updateTransactionUnitsInActive(itemId, newUnits);
    await loadPortfolio();
  }
}
