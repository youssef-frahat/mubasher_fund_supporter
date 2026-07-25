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
      final items = await repository.getPortfolioItems();
      final health = repository.calculatePortfolioHealth(items);
      emit(PortfolioLoaded(items: items, healthSummary: health));
    } catch (e) {
      emit(PortfolioError(message: 'تعذر تحميل المحفظة: ${e.toString()}'));
    }
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

    await repository.addTransaction(newItem);
    await loadPortfolio();
  }

  Future<void> removeTransaction(String id) async {
    await repository.removeTransaction(id);
    await loadPortfolio();
  }
}
