abstract class AdminState {}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}

class AdminFundsLoaded extends AdminState {
  final List<dynamic> funds;
  AdminFundsLoaded(this.funds);
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}
