# Flutter Project Architecture & Style Prompt

**قم بنسخ هذا البرومبت بالكامل واستخدامه في أي محادثة جديدة لبناء تطبيق بنفس الهيكلية (Architecture) والمستوى الاحترافي:**

---

"أريدك أن تبني تطبيق Flutter جديد بنفس المعايير الاحترافية وهيكلية العمل (Architecture) التي سأصفها لك الآن. يجب أن تلتزم بهذه القواعد بصرامة في كل سطر كود تكتبه، وتطبيق مبادئ SOLID و Clean Code:

### 1. State Management & Architecture
- **State Management:** استخدم `flutter_bloc` (تحديداً Cubit لتسهيل إدارة الحالة، مع الـ States الخاصة به: Initial, Loading, Loaded, Error).
- **Architecture:** استخدم Feature-first Folder Structure (شبيهة بـ Clean Architecture). كل ميزة (Feature) يجب أن تحتوي على:
  - `data/` (models, repositories, data sources)
  - `presentation/` (screens, widgets, cubit/bloc)
- **Dependency Injection:** استخدم `get_it` لفصل الـ Repositories والـ Cubits وتسهيل الـ Testing (في ملف `service_locator.dart`).

### 2. Routing & Navigation
- استخدم `go_router` لإدارة التنقلات.
- افصل مسارات التطبيق في ملفين: `routes.dart` (يحتوي على أسماء المسارات كثوابت `static const String`) و `app_router.dart` (يحتوي على الـ `GoRouter` والـ `GoRoute` لكل شاشة مع تمرير الـ Extras والـ Parameters).

### 3. Responsive UI & Styling
- **Responsiveness:** استخدم مكتبة `flutter_screenutil`. لا تستخدم قيم ثابتة أبداً (Hardcoded sizes). كل المقاسات يجب أن تكون:
  - `.w` و `.h` للأبعاد (Width, Height).
  - `.r` للـ Radius.
  - `.sp` للخطوط (Fonts).
- **Extensions:** قم بإنشاء واستخدام Extensions للمسافات، مثل `12.height` و `8.width` بدلاً من `SizedBox`.
- **Design System:** اعتمد على ملفات مركزية في `core/app_config/`:
  - `app_colors.dart` للألوان (Dark/Light text, Primary, Secondary, Backgrounds).
  - `font_styles.dart` لأحجام وأنواع الخطوط (مثلاً `textStyle14.copyWith(...)`).
  - `app_icons.dart` للصور والـ SVGs.

### 4. Localization
- استخدم `easy_localization`.
- الكلمات والنصوص لا يجب كتابتها مباشرة في الكود أبداً، بل يتم قراءتها من ملفات الـ JSON في `assets/translations/` باستخدام دالة `.tr()`.
- اجمع مفاتيح الترجمة (Keys) في ملف `app_strings.dart`.

### 5. Reusable Custom Widgets
يجب أن يتم بناء واجهات معتمدة على مكونات جاهزة ومخصصة (Custom Widgets) في مجلد `core/widgets/`، مثل:
- `CustomButton`: زر مخصص يدعم المقاسات والخطوط الخاصة بالتطبيق.
- `SvgImageWidget`: لعرض أي أيقونة SVG بمرونة وإعطائها ColorFilter.
- `CustomCachedNetworkImage`: لعرض الصور من الإنترنت مع Shimmer كـ Placeholder.
- `LoadingLottie` / `AppErrorWidget` / `EmptyStateWidget` للحالات المختلفة للـ UI.

### 6. Code Quality & SOLID Principles
- **DRY (Don't Repeat Yourself):** إذا كانت هناك شاشات تتشارك نفس التصميم (مثل شاشة تفاصيل لعدة أنواع من المراكز)، قم ببناء شاشة عامة (Generic Screen) ومرر لها البيانات كـ Arguments بدلاً من تكرار الشاشات (مثل `CenterDetailsScreen`).
- **Single Responsibility Principle:** كل Widget يجب أن تفعل شيئاً واحداً. قسّم الشاشة الكبيرة إلى مجموعة ملفات Widgets منفصلة داخل مجلد `presentation/widgets/`.
- استخدم `const` Constructors دائماً متى أمكن ذلك لتحسين أداء الـ Rendering.

بناءً على هذه القواعد، ابدأ بتهيئة المشروع وبناء أول Feature وهي: [اكتب اسم الميزة هنا، مثلاً: Authentication]"
flutter pub run build_runner build --delete-conflicting-outputs
