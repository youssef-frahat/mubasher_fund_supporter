import '../../data/models/portfolio_transaction.dart';

abstract class PortfolioState {}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<PortfolioTransaction> transactions;
  final Map<String, PortfolioSummary> fundSummaries;

  PortfolioLoaded(this.transactions, this.fundSummaries);
}

class PortfolioError extends PortfolioState {
  final String message;
  PortfolioError(this.message);
}

// A helper class to aggregate data for a specific fund
class PortfolioSummary {
  final String fundId;
  final String fundName;
  double totalUnits = 0;
  double totalCost = 0;

  PortfolioSummary(this.fundId, this.fundName);

  double get averageCost => totalUnits > 0 ? totalCost / totalUnits : 0;
  
  // In a real app, this would be fetched live. For MVP, we'll mock the current NAV.
  double get currentNav => averageCost * 1.05; // Assuming a 5% gain for simulation
  
  double get currentValue => totalUnits * currentNav;
  double get profitLoss => currentValue - totalCost;
  double get profitLossPercentage => totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
}
