import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TamaraPromotionWidget extends StatelessWidget {
  final double price;

  const TamaraPromotionWidget({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    if (price < 99)
      return const SizedBox.shrink(); // Tamara typically starts from 99 SAR

    final installmentAmount = (price / 4).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tamara Official Logo
          Image.network(
            'https://cdn.tamara.co/assets/png/tamara-logo-badge-en.png',
            width: 45,
            height: 45,
            errorBuilder: (context, error, stackTrace) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00D1FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'tamara',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF004DFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.notoSansArabic(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'أو قسمها على 4 دفعات بقيمة '),
                      TextSpan(
                        text: '$installmentAmount ريال ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: 'بدون رسوم خفية.'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    // Show Tamara info dialog or bottom sheet
                    _showTamaraInfo(context);
                  },
                  child: Text(
                    'لمعرفة المزيد',
                    style: GoogleFonts.notoSansArabic(
                      color: Colors.blue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTamaraInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'كيف تعمل تمارا؟',
                style: GoogleFonts.notoSansArabic(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildStep(
                context,
                '1',
                'اختر تمارا عند الدفع',
                'قسم فاتورتك على 4 دفعات بدون فوائد.',
              ),
              _buildStep(
                context,
                '2',
                'أدخل بياناتك',
                'الأمر يستغرق ثوانٍ معدودة فقط.',
              ),
              _buildStep(
                context,
                '3',
                'ادفع أول دفعة',
                'والباقي يتم خصمه تلقائياً كل شهر.',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('فهمت'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep(
    BuildContext context,
    String num,
    String title,
    String desc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansArabic(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.notoSansArabic(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
