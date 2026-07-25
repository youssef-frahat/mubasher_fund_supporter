import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_config/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBackground(context);
    final surface = AppColors.getSurface(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border = AppColors.getBorder(context);

    final faqs = [
      {
        'q': 'ما هي منصة "وثيقة Watheqa"؟',
        'a': 'منصة "وثيقة" هي حليفك الذكي للاستثمار في مصر، توفر لك محاكاة للمحفظة، أداة مقارنة بين الصناديق والشهادات البنكية والذهب، ومستشار استثماري مخصص.',
      },
      {
        'q': 'كيف يتم حساب عائد الصناديق والمحفظة؟',
        'a': 'يتم التقييم وفقاً لبيانات صافي قيمة الأصول (NAV) المحدثة من البنوك وشركات إدارة الأصول المصرية مثل أزموت وهيرميس وبلتون وسي أي كابيتال.',
      },
      {
        'q': 'ما الفرق بين صناديق النقدية والأسهم والذهب؟',
        'a': 'الصناديق النقدية تعطي عائداً يومياً آمن ومستقر، صناديق الذهب تحمي أموالك من التضخم، وصناديق الأسهم تهدف إلى تحقيق نمو مرتفع في رأس المال على المدى الطويل.',
      },
      {
        'q': 'هل التطبيق مجاني؟',
        'a': 'نعم، المنصة والمحاكي والمستشار الاستثماري متوفرين مجاناً 100% لجميع المستخدمين.',
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
          'الأسئلة الشائعة (FAQ)',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20.r),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final item = faqs[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: border),
            ),
            child: ExpansionTile(
              leading: const FaIcon(FontAwesomeIcons.circleQuestion, color: AppColors.primary, size: 20),
              title: Text(
                item['q']!,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Text(
                    item['a']!,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11.sp,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
