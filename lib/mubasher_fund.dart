import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/portfolio/presentation/cubit/portfolio_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/language/language_cubit.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';

class MubasherFund extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MubasherFund({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<AuthCubit>()),
            BlocProvider(create: (_) => sl<PortfolioCubit>()),
            BlocProvider(create: (_) => ThemeCubit(prefs)),
            BlocProvider(create: (_) => LanguageCubit(prefs)),
          ],
          child: BlocBuilder<LanguageCubit, Locale>(
            builder: (context, currentLocale) {
              return BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return MaterialApp.router(
                    title: 'Watheqa',
                    debugShowCheckedModeBanner: false,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: currentLocale,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeMode,
                    routerConfig: AppRouter.router,
                    builder: (context, child) {
                      return Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
