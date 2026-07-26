import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/models/fund_model.dart';
import '../../../home/data/repositories/funds_repository.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final FundsRepository repository;

  AdminCubit(this.repository) : super(AdminInitial());

  Future<void> loadFunds() async {
    emit(AdminLoading());
    try {
      final funds = await repository.getFunds();
      emit(AdminFundsLoaded(funds));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> addFund(FundModel fund) async {
    try {
      emit(AdminLoading());
      await repository.addFund(fund);
      await loadFunds();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateFund(FundModel fund) async {
    try {
      emit(AdminLoading());
      await repository.updateFund(fund);
      await loadFunds();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteFund(String id) async {
    try {
      emit(AdminLoading());
      await repository.deleteFund(id);
      await loadFunds();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
