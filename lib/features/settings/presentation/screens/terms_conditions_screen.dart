import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/app_config/app_colors.dart';
import '../../../../core/language/language_cubit.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);
    final isAr = context.isArabic;

    final sections = isAr
        ? [
            {
              'title': '1. طبيعة المنصة والمحاكاة الاستثمارية:',
              'body':
                  'منصة "وثيقة" هي منصة استشارية ومحاكاة ذكية لمساعدة المستثمرين في مصر على متابعة ومقارنة صناديق الاستثمار وتقييم الأداء والمخاطر. العمليات المالية داخل التطبيق هي عمليات محاكاة افتراضية لأغراض التخطيط والتعليم.',
            },
            {
              'title': '2. دقة بيانات وثائق الاستثمار (NAV):',
              'body':
                  'يتم تحديث أسعار الوثائق والبيانات المالية وفقاً للمصادر الرسمية الصادرة عن مديري الاستثمار والبنوك المصرية. قد تختلف وتيرة التحديث (يومياً أو أسبوعياً) بحسب طبيعة كل صندوق.',
            },
            {
              'title': '3. حماية وخصوصية البيانات:',
              'body':
                  'نلتزم بأعلى معايير التشفير والأمان لحماية بيانات حسابك ومعلومات محفظتك الشخصية. لا يتم مشاركة بياناتك مع أي أطراف خارجية بدون موافقتك الصريحة.',
            },
            {
              'title': '4. إخلاء المسؤولية القانونية:',
              'body':
                  'التحليلات والتوصيات الصادرة عن المستشار الذكي هي لأغراض استرشادية مبنية على نموذج تحليل المخاطر، ولا تعتبر دعوة مباشرة للشراء دون مراجعة نشرة اكتتاب الصندوق الرسمية.',
            },
          ]
        : [
            {
              'title': '1. Platform Nature & Investment Simulation:',
              'body':
                  'Watheqa is an intelligent advisory and simulation platform designed to help Egyptian investors track, compare, and evaluate mutual funds. All financial operations within the app are virtual simulations for planning and educational purposes only.',
            },
            {
              'title': '2. NAV Data Accuracy:',
              'body':
                  'Unit prices and financial data are updated according to official sources from fund managers and Egyptian banks. Update frequency (daily or weekly) may vary depending on each fund.',
            },
            {
              'title': '3. Data Protection & Privacy:',
              'body':
                  'We comply with the highest encryption and security standards to protect your account data and portfolio information. Your data is never shared with third parties without your explicit consent.',
            },
            {
              'title': '4. Legal Disclaimer:',
              'body':
                  'Analyses and recommendations from the Smart Advisor are for informational purposes based on a risk analysis model and do not constitute a direct solicitation to buy without reviewing the official fund prospectus.',
            },
          ];

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
          context.tr('privacyPolicy'),
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.fileContract, color: AppColors.primary, size: 18.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'شروط الاستخدام لمنصة "وثيقة Watheqa"'
                          : 'Terms of Use — Watheqa Platform',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              ...sections.map((s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['title']!,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        s['body']!,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
