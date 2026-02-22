import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TabbyPromotionWidget extends StatelessWidget {
  final double price;

  const TabbyPromotionWidget({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    if (price < 10) return const SizedBox.shrink();

    final installmentAmount = (price / 4).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
          // Tabby Official Logo
          Image.network(
            'https://cdn.tabby.ai/assets/logo.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3DFADA).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'tabby',
                style: GoogleFonts.poppins(
                  color: Colors.black,
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
                      const TextSpan(text: 'قسمها على 4 دفعات شهرية بقيمة '),
                      TextSpan(
                        text: '$installmentAmount ريال ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: 'بدون فوائد.'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => _showTabbyInfo(context),
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

  void _showTabbyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.keyboard_arrow_down),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.network(
                        'https://cdn.tabby.ai/assets/logo.png',
                        height: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'تسوق الآن، وادفع لاحقاً مع تابي.',
                      style: GoogleFonts.notoSansArabic(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildStep(
                      '1',
                      'اختر تابي عند الدفع',
                      'قسم مشترياتك على 4 دفعات شهرية متساوية.',
                    ),
                    _buildStep(
                      '2',
                      'أدخل بياناتك',
                      'اربط أي بطاقة بنكية واحصل على موافقة فورية.',
                    ),
                    _buildStep(
                      '3',
                      'قسمها وبس!',
                      'ادفع الدفعة الأولى الآن، والباقي على 3 أشهر. لا فوائد، لا رسوم.',
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3DFADA),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'فهمت',
                          style: GoogleFonts.notoSansArabic(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF3DFADA),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.notoSansArabic(
                    fontSize: 14,
                    color: Colors.grey.shade600,
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
