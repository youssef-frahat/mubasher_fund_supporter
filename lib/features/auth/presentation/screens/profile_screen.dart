import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/services/permissions_service.dart';
import '../../../../core/services/avatar_picker_service.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController(text: '01002938471');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'تعديل بيانات الحساب',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            _nameController.text = state.user.userMetadata?['full_name'] ?? 'مستثمر مباشر';

            return SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  // User Avatar Header with Camera Edit Button
                  GestureDetector(
                    onTap: () async {
                      final file = await AvatarPickerService.pickAndCropAvatar(context);
                      if (file != null && mounted) {
                        setState(() => _avatarFile = file);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50.r,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                          child: _avatarFile == null
                              ? FaIcon(
                                  FontAwesomeIcons.userCheck,
                                  color: AppColors.primary,
                                  size: 45.r,
                                )
                              : null,
                        ),
                        CircleAvatar(
                          radius: 16.r,
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  Text(
                    state.user.email ?? '',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Edit Form Container
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'الاسم بالكامل',
                            labelStyle: TextStyle(color: textSecondary),
                            prefixIcon: Icon(Icons.person_outline, color: textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف (للتنبيهات)',
                            labelStyle: TextStyle(color: textSecondary),
                            prefixIcon: Icon(Icons.phone_outlined, color: textSecondary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Risk Preference Selector
                        Text(
                          'الملف الاستثماري المفضل:',
                          style: TextStyle(color: textSecondary, fontSize: 12.sp),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.shieldHalved, color: AppColors.primary, size: 16),
                              SizedBox(width: 10.w),
                              Text(
                                'مستثمر متوازن (حفظ رأس المال والنمو)',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),

                  // Save Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ بيانات الحساب بنجاح! 💾'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        context.pop();
                      },
                      icon: const FaIcon(FontAwesomeIcons.floppyDisk, color: Colors.black, size: 16),
                      label: const Text(
                        'حفظ التغييرات',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                'يرجى تسجيل الدخول لتعديل بيانات حسابك.',
                style: TextStyle(color: textSecondary),
              ),
            );
          }
        },
      ),
    );
  }
}
