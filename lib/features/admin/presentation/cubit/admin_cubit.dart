import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../home/data/models/platform_feature.dart';
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

  Future<void> addFund(PlatformFeature fund) async {
    try {
      await repository.addFund(fund);
      loadFunds(); // Reload after adding
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteFund(String id) async {
    try {
      await repository.deleteFund(id);
      loadFunds(); // Reload after deleting
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
