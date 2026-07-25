import '../../data/models/portfolio_item_model.dart';
import '../../data/models/portfolio_model.dart';

abstract class PortfolioState {}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<PortfolioModel> allPortfolios;
  final PortfolioModel activePortfolio;
  final List<PortfolioItem> items;
  final PortfolioHealthSummary healthSummary;

  PortfolioLoaded({
    required this.allPortfolios,
    required this.activePortfolio,
    required this.items,
    required this.healthSummary,
  });
}

class PortfolioError extends PortfolioState {
  final String message;

  PortfolioError({required this.message});
}
