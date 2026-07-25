import '../../data/models/portfolio_item_model.dart';

abstract class PortfolioState {}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<PortfolioItem> items;
  final PortfolioHealthSummary healthSummary;

  PortfolioLoaded({
    required this.items,
    required this.healthSummary,
  });
}

class PortfolioError extends PortfolioState {
  final String message;

  PortfolioError({required this.message});
}
