import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'الشروط والأحكام وسياسة الخصوصية',
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
              Text(
                'شروط الاستخدام لمنصة "وثيقة Watheqa"',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 12.h),

              _buildPolicySection(
                title: '1. طبيعة المنصة والمحاكاة الاستثمارية:',
                body: 'منصة "وثيقة" هي منصة استشارية ومحاكاة ذكية لمساعدة المستثمرين في مصر على متابعة ومقارنة صناديق الاستثمار وتقييم الأداء والمخاطر. العمليات المالية داخل التطبيق هي عمليات محاكاة افتراضية لأغراض التخطيط والتعليم.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              SizedBox(height: 14.h),

              _buildPolicySection(
                title: '2. دقة بيانات وثائق الاستثمار (NAV):',
                body: 'يتم تحديث أسعار الوثائق والبيانات المالية وفقاً للمصادر الرسمية الصادرة عن مديري الاستثمار والبنوك المصرية. قد تختلف وتيرة التحديث (يومياً أو أسبوعياً) بحسب طبيعة كل صندوق.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              SizedBox(height: 14.h),

              _buildPolicySection(
                title: '3. حماية وخصوصية البيانات:',
                body: 'نلتزم بأعلى معايير التشفير والأمان لحماية بيانات حسابك ومعلومات محفظتك الشخصية. لا يتم مشاركة بياناتك مع أي أطراف خارجية بدون موافقتك الصريحة.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              SizedBox(height: 14.h),

              _buildPolicySection(
                title: '4. إخلاء المسؤولية القانونية:',
                body: 'التحليلات والتوصيات الصادرة عن المستشار الذكي هي لأغراض استرشادية مبنية على نموذج تحليل المخاطر، ولا تعتبر دعوة مباشرة للشراء دون مراجعة نشرة اكتتاب الصندوق الرسمية.',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required String body,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          body,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11.sp,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
