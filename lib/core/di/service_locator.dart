import 'package:get_it/get_it.dart';

import '../../features/home/data/repositories/funds_repository.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Setup Repositories and Data Sources here
  sl.registerLazySingleton<FundsRepository>(() => SupabaseFundsRepository());

  // Setup Blocs/Cubits here
  sl.registerFactory(() => HomeCubit(sl()));
  sl.registerFactory(() => AdminCubit(sl()));
  sl.registerLazySingleton(() => AuthCubit());
}
