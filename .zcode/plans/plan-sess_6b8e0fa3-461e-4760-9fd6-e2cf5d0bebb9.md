# خطة إضافة ثيم Liquid Glass لتطبيق أقم

**القرارات المعتمدة** (من اختياراتك): مكتبة `liquid_glass_plus` — خيار ثالث في مختار الثيمات الحالي — طبقة خلفية متدرجة مركزية تظهر مع الزجاج فقط — مظهر زجاج فاتح بنصوص داكنة.

**القيود الثابتة**: صفر `StatefulWidget` جديد في التطبيق، فصل كامل بين UI والمنطق (المنطق في `ThemeController` فقط)، لا مساس بمنطق المواقيت/الأذان/البوصلة، احترام نمط GetX + GetStorage القائم.

## الفكرة المعمارية الأساسية

نقل قرارات الزجاج عبر `ThemeExtension` باسم `GlassTokens` يُرفق بـ `liquidGlassTheme` فقط. كل مكوّن يقرأ `context.theme.extension<GlassTokens>()` — إن كانت `null` يرسم التصميم الكلاسيكي الحالي كما هو، وإن وُجدت يرسم الزجاج. بهذا:
- الواجهات لا تستورد أي متحكم (فصل UI/منطق).
- الثيمان الحاليان (blue/dark) لا يتأثران بسطر واحد.
- إعادة البناء عند التبديل تسري عبر آلية `GetBuilder` + `Get.forceAppUpdate()` الموجودة أصلًا.

## المرحلة 1 — البنية التحتية للثيم (منطق فقط)

1. **`pubspec.yaml`**: إضافة `liquid_glass_plus: ^0.3.2` ثم `flutter pub get` + `dart analyze` فورًا للتحقق من التوافق مع Flutter ≥3.44 قبل أي عمل آخر (نقطة فشل مبكرة).
2. **ملف جديد `lib/core/utils/helpers/glass_tokens.dart`**: `GlassTokens extends ThemeExtension<GlassTokens>` يحمل: `LiquidGlassSettings` بنسختين (`hero` للبطاقات الكبيرة: thickness/frost أعلى، و`subtle` للبطاقات الصغيرة والقوائم: خفيف للأداء)، لون الزجاج، وألوان تدرج الخلفية.
3. **`lib/core/utils/helpers/app_themes.dart`**: إضافة `liquidGlassTheme` — `ThemeData.light(useMaterial3: false)` بخط cairo، `ColorScheme` بـ `brightness: Brightness.light` صحيحة، نصوص داكنة، وأدوار سطح شبه شفافة (surface/primaryContainer بشفافية) حتى تظهر خلفية التدرج من خلف الـ Scaffold، مع `extensions: [GlassTokens.defaults()]`.
4. **`lib/presentation/controllers/theme_controller.dart`**: `enum AppTheme { blue, dark, liquidGlass }` + الحالة الثالثة في المواضع الثلاثة (`checkTheme`/`setTheme`/`currentThemeData`) + `bool get isLiquidGlass`. التخزين يعمل تلقائيًا بدولاب `SET_THEME` الحالي (`toString()`/`firstWhere`) دون مفتاح جديد.

## المرحلة 2 — مكونات زجاجية مركزية (Stateless بالكامل)

5. **ملف جديد `lib/core/widgets/glass/glass_container.dart`**: `GlassContainer` — StatelessWidget بمعاملات `{child, radius, variant, padding, onTap}`. بدون `GlassTokens` → حاوية عادية بألوان الثيم (Classic). معها → `LiquidGlass.withOwnLayer` بشكل `LiquidRoundedSuperellipse`. العناصر القابلة للنقر تُلف بـ `GlassGlow` (توهج اللمس). **هذا هو الـ GlassCard/GlassContainer المطلوب**.
6. **ملف جديد `lib/core/widgets/glass/glass_background.dart`**: `GlassBackground` — StatelessWidget يرسم تدرجًا لونيًا بهوية التطبيق + 2–3 هالات شعاعية ناعمة، ويقرأ الألوان من `GlassTokens`.
7. **`my_app.dart`**: في الـ `builder` الحالي، لف الـ child بـ `Stack` يضع `GlassBackground` في الأسفل **فقط** عند `AppTheme.liquidGlass`.
8. **جولة شفافية**: مسح الشاشات الثلاث-الأربع التي ترسم حاويات بلون معتم مباشرة (prayer/qibla body) وتحويلها لأدوار الثيم لتسمح بمرور الخلفية.

## المرحلة 3 — التطبيق التدريجي

9. **شريط التنقل** (`home_screen.dart`): تفعيل السطر المعلّق `glassEffect` شرطيًا — `isLiquidGlass ? const FloaticaGlassEffect.liquidGlass() : null` — لأن شريط FloatyNavBar له تنفيذ زجاج أصلي مخصص له (لفّه بشكل LiquidGlass خارجي سيتطلب جراحة Stack ويكسر داخله؛ التأثيران مضبوطان على نفس مواصفات iOS 26 الفاتح فيبدوان متناسقين).
10. **`container_button_widget.dart`**: تفرّع واحد — عند وجود `GlassTokens` يُعرض المحتوى داخل `GlassContainer` بدل التدرج الحالي. هذا الملف هو البطاقة المنتشرة في كل التطبيق، فيغطي التعديل معظم الواجهات دفعة واحدة.
11. **`bottom_sheet_extension.dart`**: نسخة زجاجية من حاوية الشيت (زوايا علوية 16) تغطي كل مواقع الاستدعاء العشرة تلقائيًا.
12. **البطاقات البطلة**: بطاقة الصلاة القادمة ونتيجة المواقيت بـ variant `hero`، بطاقة رأس القبلة، وقوائم المدن بـ `subtle`.
13. **واجهة الاختيار**: مدخل رابع في `themeList` (`lists.dart`) + مفتاح ترجمة `liquidGlassMode` في ملفات اللغات الـ 11 (مع إصلاح مفتاحَي `oldMode`/`darkMode` المفقودين أصلًا). `theme_change.dart` لا يحتاج تعديلًا — يبني البلاطات من القائمة تلقائيًا.

## المرحلة 4 — الاختبارات والتحقق

14. **اختبارات جديدة** (بالقالب القائم في `test/`):
    - `theme_controller_liquid_glass_test.dart`: دورة حفظ/استعادة الخيار الثالث + `currentThemeData` + `isLiquidGlass`.
    - `glass_container_test.dart`: يرسم الكلاسيكي بدون extension، والزجاج معها.
    - `theme_switch_test.dart`: ثلاث بلاطات في الإعدادات والتبديل يعمل (قالب `floaty_menu_navigation_test.dart`).
15. `dart format` + `flutter analyze` نظيفان + تمرير الاختبارات الحالية.
16. **مصفوفة تحقق يدوية**: macOS (Impeller حقيقي)، آيفون وآندرويد حقيقيان بـ `--profile` (فحص الانزلاق مع البطاقات الزجاجية المتحركة)، الويب (شكل fake glass المقبول)، وضوح النص العربي RTL فوق التدرج، وتأكيد عدم تغير سلوك الأذان/البوصلة.

## المخاطر وخطط الاحتواء

- **توافق الحزمة مع Flutter 3.44**: يُفحص في الخطوة 1 قبل أي شيء؛ الاحتواء: تثبيت نسخة متوافقة أو الرجوع لتنفيذ floatica خلف نفس واجهة `GlassTokens` دون تغيير الشاشات.
- **أداء على Skia/أجهزة أندرويد الضعيفة** (الحزمة تنصح بتقليل مساحات الطبقات): نسخة `subtle` خفيفة، الزجاج الكثيف للبطاقات البطلة فقط، وإن لزم تُخفض التغطية على الأجهزة الضعيفة.
- **تباين النصوص فوق التدرج**: نصوص داكنة + تدرج فاتح، مع تحقق يدوي.

## الحجم التقريبي

4 ملفات جديدة (`glass_tokens`, `glass_container`, `glass_background`, الاختبارات) + ~9 ملفات معدلة + 11 ملف لغة بمفتاح واحد. لا حذف ولا إعادة هيكلة — كل التعديلات إضافية على البنية القائمة.