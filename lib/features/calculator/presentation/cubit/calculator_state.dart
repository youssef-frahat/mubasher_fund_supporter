import '../../data/models/risk_profile_model.dart';
import '../../data/models/sponsored_fund_model.dart';

abstract class CalculatorState {}

class CalculatorInitial extends CalculatorState {}

class CalculatorCalculating extends CalculatorState {}

class CalculatorCalculated extends CalculatorState {
  final double amount;
  final InvestmentGoal goal;
  final InvestmentDuration duration;
  final RiskAssessmentResult riskResult;
  final SponsoredFundModel? sponsoredFund;
  final double bankCertificateReturn; // ROI for bank cert
  final double fundEstimatedReturn;   // ROI for recommended fund
  final double goldEstimatedReturn;   // ROI for gold

  CalculatorCalculated({
    required this.amount,
    required this.goal,
    required this.duration,
    required this.riskResult,
    required this.sponsoredFund,
    required this.bankCertificateReturn,
    required this.fundEstimatedReturn,
    required this.goldEstimatedReturn,
  });
}
