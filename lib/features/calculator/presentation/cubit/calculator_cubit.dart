import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/risk_profile_model.dart';
import '../../data/repositories/calculator_repository.dart';
import 'calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  final CalculatorRepository repository;

  CalculatorCubit({required this.repository}) : super(CalculatorInitial());

  double selectedAmount = 100000.0;
  InvestmentGoal selectedGoal = InvestmentGoal.capitalPreservation;
  InvestmentDuration selectedDuration = InvestmentDuration.mediumTerm;

  void updateAmount(double amount) {
    selectedAmount = amount;
    calculate();
  }

  void updateGoal(InvestmentGoal goal) {
    selectedGoal = goal;
    calculate();
  }

  void updateDuration(InvestmentDuration duration) {
    selectedDuration = duration;
    calculate();
  }

  Future<void> calculate() async {
    emit(CalculatorCalculating());

    final riskResult = repository.calculateRiskProfile(
      goal: selectedGoal,
      duration: selectedDuration,
    );

    // Compound ROI Calculations
    double years = selectedDuration == InvestmentDuration.shortTerm
        ? 1.0
        : (selectedDuration == InvestmentDuration.mediumTerm ? 2.0 : 3.0);

    // Bank Cert constant rate (e.g., 23.5% per annum)
    double bankRate = 0.235;
    double bankCertReturn = selectedAmount * (1 + (bankRate * years));

    // Recommended Multi-Fund Portfolio Mix Rate
    double fundRate = riskResult.expectedRoiPercentage / 100.0;
    double fundReturn = selectedAmount * (1 + (fundRate * years));

    // Gold estimated rate (e.g. 27.5% per annum)
    double goldRate = 0.275;
    double goldReturn = selectedAmount * (1 + (goldRate * years));

    emit(
      CalculatorCalculated(
        amount: selectedAmount,
        goal: selectedGoal,
        duration: selectedDuration,
        riskResult: riskResult,
        bankCertificateReturn: bankCertReturn,
        fundEstimatedReturn: fundReturn,
        goldEstimatedReturn: goldReturn,
      ),
    );
  }
}
