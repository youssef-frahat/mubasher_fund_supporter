import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';
import '../../../../core/widgets/app_snackbar.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const String _developerPortfolioUrl = 'https://v0-youssef-farahat.vercel.app/';

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } catch (err) {
        if (context.mounted) {
          AppSnackBar.showWarning(context, context.isArabic ? 'تعذر فتح الرابط في المتصفح' : 'Could not open link in browser');
        }
      }
    }
  }

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    AppSnackBar.showSuccess(
      context,
      context.isArabic ? 'تم نسخ رابط بورتفوليو المطور بنجاح 📋 🚀' : 'Developer portfolio URL copied successfully! 📋 🚀',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

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
          isAr ? '🤝 من نحن' : '🤝 About Us',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10.h),

            // App Logo / Brand Header
            Container(
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(45.r),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 90.r,
                  height: 90.r,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        'W',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            Text(
              isAr ? 'وثيقة | Watheqa' : 'Watheqa | وثيقة',
              style: TextStyle(
                color: textPrimary,
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isAr
                  ? 'منصة محاكي صناديق الاستثمار المصرية الذكية'
                  : 'Smart Egyptian Mutual Funds Simulator Platform',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // About App Card
            _buildCard(
              surface: surface,
              border: border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: const FaIcon(FontAwesomeIcons.circleInfo, color: AppColors.primary, size: 16),
                    label: isAr ? 'عن التطبيق' : 'About the App',
                    textPrimary: textPrimary,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    isAr
                        ? 'وثيقة هو تطبيق متخصص في محاكاة وتحليل صناديق الاستثمار المصرية. يمكنك من خلاله:\n\n• بناء محفظة استثمارية محاكاة كاملة\n• مقارنة أداء 200+ صندوق استثمار\n• الحصول على توصيات المستشار الذكي\n• متابعة إشارات الشراء والبيع اليومية\n• تتبع عائد الذهب والشهادات والصناديق'
                        : 'Watheqa is a specialized app for simulating and analyzing Egyptian mutual funds. It allows you to:\n\n• Build a complete simulated investment portfolio\n• Compare 200+ investment funds\n• Get Robo-Advisor recommendations\n• Track daily buy/sell signals\n• Follow gold, certificates & fund returns',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.sp,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Developer Card
            _buildCard(
              surface: surface,
              border: border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: const FaIcon(FontAwesomeIcons.code, color: AppColors.primary, size: 16),
                    label: isAr ? 'المطوّر' : 'Developer',
                    textPrimary: textPrimary,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Container(
                        width: 60.r,
                        height: 60.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: Image.asset(
                            'assets/images/developer.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => CircleAvatar(
                              radius: 28.r,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: FaIcon(FontAwesomeIcons.userTie, color: AppColors.primary, size: 24.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Youssef Farahat',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              isAr
                                  ? 'Flutter Developer & UI/UX Designer'
                                  : 'Flutter Developer & UI/UX Designer',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchUrl(context, _developerPortfolioUrl),
                          icon: FaIcon(FontAwesomeIcons.globe, color: Colors.black, size: 15.r),
                          label: Text(
                            isAr ? '🔗 فتح البورتفوليو' : '🔗 Open Portfolio',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 8.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        flex: 4,
                        child: ElevatedButton.icon(
                          onPressed: () => _copyUrl(context, _developerPortfolioUrl),
                          icon: FaIcon(FontAwesomeIcons.copy, color: Colors.white, size: 15.r),
                          label: Text(
                            isAr ? '📋 نسخ الرابط' : '📋 Copy Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 8.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),

                  // URL Preview Badge
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.link, color: AppColors.primary, size: 11.r),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _developerPortfolioUrl,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // App Version & Credits Card
            _buildCard(
              surface: surface,
              border: border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    icon: const FaIcon(FontAwesomeIcons.circleCheck, color: AppColors.primary, size: 16),
                    label: isAr ? 'معلومات الإصدار' : 'Version Info',
                    textPrimary: textPrimary,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoRow(
                    label: isAr ? 'الإصدار:' : 'Version:',
                    value: '1.0.0',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  SizedBox(height: 6.h),
                  _buildInfoRow(
                    label: isAr ? 'المنصة:' : 'Platform:',
                    value: 'Flutter (iOS & Android)',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  SizedBox(height: 6.h),
                  _buildInfoRow(
                    label: isAr ? 'البيانات:' : 'Data Source:',
                    value: 'Egyptian Capital Market Authority',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  SizedBox(height: 6.h),
                  _buildInfoRow(
                    label: isAr ? 'البريد الإلكتروني:' : 'Email:',
                    value: 'support@watheqa.eg',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Footer copyright
            Text(
              isAr
                  ? '© 2025 وثيقة (Watheqa) — جميع الحقوق محفوظة'
                  : '© 2025 Watheqa — All Rights Reserved',
              style: TextStyle(
                color: textSecondary,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Color surface, required Color border, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle({
    required Widget icon,
    required String label,
    required Color textPrimary,
  }) {
    return Row(
      children: [
        icon,
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            color: textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 11.sp,
            ),
          ),
        ),
      ],
    );
  }
}
