# دليل استخدام السلايدر للماركات (Brand Slider Guide)

## 📋 نظرة عامة

تم إضافة إمكانية ربط البنرات بالماركات (Brands) في السلايدر، تماماً مثل الفئات (Categories). الآن يمكنك عرض الماركات في السلايدر العلوي للتطبيق مع صور مخصصة.

---

## ✨ الميزات الجديدة

### 1. **إظهار في السلايدر**
- خيار لإظهار/إخفاء الماركة في السلايدر العلوي للتطبيق
- يعمل بشكل مستقل عن خيار "إظهار في التطبيق"

### 2. **صورة السلايدر المخصصة**
- رفع صورة مخصصة للسلايدر بأبعاد 16:9
- معاينة الصورة قبل الحفظ
- إمكانية إزالة الصورة

### 3. **REST API**
- إضافة حقل `slider_data` لـ REST API الخاص بالماركات
- يحتوي على:
  - `is_featured`: هل تظهر في السلايدر؟
  - `slider_image`: رابط صورة السلايدر

---

## 🔧 كيفية الاستخدام

### في لوحة تحكم WordPress:

#### **إضافة ماركة جديدة:**
1. اذهب إلى **المنتجات > الماركات**
2. انقر على **إضافة ماركة جديدة**
3. ستجد الحقول التالية:
   - ✅ **إظهار في التطبيق**: للتحكم في ظهور الماركة في الصفحة الرئيسية
   - ✅ **إظهار في سلايدر التطبيق**: لإظهار الماركة في السلايدر
   - ✅ **صورة السلايدر المخصصة**: لرفع صورة بأبعاد 16:9

#### **تعديل ماركة موجودة:**
1. اذهب إلى **المنتجات > الماركات**
2. انقر على اسم الماركة لتعديلها
3. قم بتفعيل **إظهار في سلايدر التطبيق**
4. ارفع صورة مخصصة للسلايدر
5. احفظ التغييرات

---

## 📡 REST API

### **نقطة الاتصال (Endpoint):**
```
GET /wp-json/wc/v3/products/brands
```

### **البيانات المُرجعة:**
```json
{
  "id": 123,
  "name": "Apple",
  "slug": "apple",
  "description": "وصف الماركة",
  "image": {
    "id": 456,
    "src": "https://example.com/apple-logo.jpg",
    "name": "Apple Logo"
  },
  "app_settings": {
    "show_in_app": true
  },
  "slider_data": {
    "is_featured": true,
    "slider_image": "https://example.com/apple-slider.jpg"
  }
}
```

---

## 🎨 في تطبيق Flutter

### **نموذج البيانات (Model):**

تأكد من أن نموذج `WooBrand` يحتوي على:

```dart
class WooBrand {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final WooProductImage? image;
  final bool isVisibleInApp;
  final SliderData? sliderData; // ← جديد

  WooBrand({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.isVisibleInApp = true,
    this.sliderData, // ← جديد
  });

  factory WooBrand.fromJson(Map<String, dynamic> json) {
    // ... الكود الموجود
    
    // إضافة بيانات السلايدر
    SliderData? brandSliderData;
    if (json['slider_data'] != null) {
      brandSliderData = SliderData.fromJson(json['slider_data']);
    }

    return WooBrand(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      image: brandImage,
      isVisibleInApp: showInApp,
      sliderData: brandSliderData, // ← جديد
    );
  }
}

// نموذج بيانات السلايدر
class SliderData {
  final bool isFeatured;
  final String? sliderImage;

  SliderData({
    required this.isFeatured,
    this.sliderImage,
  });

  factory SliderData.fromJson(Map<String, dynamic> json) {
    return SliderData(
      isFeatured: json['is_featured'] ?? false,
      sliderImage: json['slider_image'],
    );
  }
}
```

### **استخدام في السلايدر:**

```dart
// جلب الماركات التي تظهر في السلايدر
List<WooBrand> getSliderBrands(List<WooBrand> brands) {
  return brands.where((brand) => 
    brand.sliderData?.isFeatured == true &&
    brand.sliderData?.sliderImage != null
  ).toList();
}

// عرض في السلايدر
Widget buildBrandSlider(List<WooBrand> brands) {
  final sliderBrands = getSliderBrands(brands);
  
  return CarouselSlider(
    items: sliderBrands.map((brand) {
      return GestureDetector(
        onTap: () => navigateToBrandProducts(brand),
        child: CachedNetworkImage(
          imageUrl: brand.sliderData!.sliderImage!,
          fit: BoxFit.cover,
        ),
      );
    }).toList(),
    options: CarouselOptions(
      height: 200,
      aspectRatio: 16/9,
      autoPlay: true,
    ),
  );
}
```

---

## 🔄 دمج مع السلايدر الموجود

يمكنك دمج سلايدر الماركات مع سلايدر الفئات:

```dart
class SliderItem {
  final String imageUrl;
  final String type; // 'category' or 'brand'
  final int id;
  final String name;

  SliderItem({
    required this.imageUrl,
    required this.type,
    required this.id,
    required this.name,
  });
}

List<SliderItem> getCombinedSliderItems(
  List<WooProductCategory> categories,
  List<WooBrand> brands,
) {
  List<SliderItem> items = [];
  
  // إضافة الفئات
  for (var cat in categories) {
    if (cat.sliderData?.isFeatured == true && 
        cat.sliderData?.sliderImage != null) {
      items.add(SliderItem(
        imageUrl: cat.sliderData!.sliderImage!,
        type: 'category',
        id: cat.id,
        name: cat.name,
      ));
    }
  }
  
  // إضافة الماركات
  for (var brand in brands) {
    if (brand.sliderData?.isFeatured == true && 
        brand.sliderData?.sliderImage != null) {
      items.add(SliderItem(
        imageUrl: brand.sliderData!.sliderImage!,
        type: 'brand',
        id: brand.id,
        name: brand.name,
      ));
    }
  }
  
  return items;
}
```

---

## 📝 ملاحظات مهمة

1. **أبعاد الصورة**: يُنصح باستخدام صور بنسبة 16:9 (مثل 1920×1080 أو 1280×720)
2. **حجم الصورة**: يُفضل ألا يتجاوز حجم الصورة 500KB لتحسين الأداء
3. **الترتيب**: يمكنك التحكم في ترتيب ظهور العناصر في السلايدر من خلال ترتيب الماركات والفئات
4. **الأداء**: استخدم `CachedNetworkImage` في Flutter لتحسين أداء تحميل الصور

---

## 🐛 استكشاف الأخطاء

### **المشكلة: الصورة لا تظهر في API**
- تأكد من أن الصورة تم رفعها بنجاح
- تحقق من أن خيار "إظهار في سلايدر التطبيق" مفعّل
- تأكد من حفظ التغييرات

### **المشكلة: الماركة لا تظهر في السلايدر**
- تحقق من `slider_data.is_featured` في API
- تأكد من وجود `slider_data.slider_image`
- تحقق من منطق الفلترة في التطبيق

---

## 📞 الدعم

للمزيد من المساعدة، يرجى التواصل مع:
- **المطور**: Mohamed Yussry
- **الموقع**: https://mohamedyussry.github.io/

---

## 📄 الترخيص

هذه الإضافة جزء من **App Core Plugin** v1.1.0
