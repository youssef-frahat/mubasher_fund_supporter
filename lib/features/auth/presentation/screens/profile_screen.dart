import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/routes.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/services/permissions_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50.r,
                    child: Icon(Icons.person, size: 50.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    state.user.userMetadata?['full_name'] ?? 'User',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    state.user.email ?? '',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final granted = await PermissionsService.requestNotificationPermission(context);
                      if (granted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications Enabled!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications),
                    label: const Text('Enable Notifications'),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final granted = await PermissionsService.requestPhotosPermission(context);
                      if (granted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo Access Granted!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Change Profile Picture'),
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthCubit>().signOut();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Logout', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are not logged in.'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      context.push(Routes.login);
                    },
                    child: const Text('Login / Register'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
