import '../../data/models/risk_profile_model.dart';

abstract class CalculatorState {}

class CalculatorInitial extends CalculatorState {}

class CalculatorCalculating extends CalculatorState {}

class CalculatorCalculated extends CalculatorState {
  final double amount;
  final InvestmentGoal goal;
  final InvestmentDuration duration;
  final RiskAssessmentResult riskResult;
  final double bankCertificateReturn; // ROI for bank cert
  final double fundEstimatedReturn;   // ROI for recommended multi-fund portfolio
  final double goldEstimatedReturn;   // ROI for gold

  CalculatorCalculated({
    required this.amount,
    required this.goal,
    required this.duration,
    required this.riskResult,
    required this.bankCertificateReturn,
    required this.fundEstimatedReturn,
    required this.goldEstimatedReturn,
  });
}
