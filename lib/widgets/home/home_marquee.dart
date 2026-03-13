import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/update_service.dart';
import 'package:myapp/providers/language_provider.dart';

class HomeMarquee extends StatelessWidget {
  const HomeMarquee({super.key});

  @override
  Widget build(BuildContext context) {
    final updateInfo = UpdateService().updateInfo;
    if (updateInfo == null) return const SizedBox.shrink();

    final isEnabled = updateInfo['marquee_enabled'] ?? false;
    if (!isEnabled) return const SizedBox.shrink();

    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.appLocale.languageCode == 'ar';
    
    final text = isArabic 
        ? (updateInfo['marquee_text_ar'] ?? '')
        : (updateInfo['marquee_text_en'] ?? '');

    if (text.isEmpty) return const SizedBox.shrink();

    final bgColor = _parseColor(updateInfo['marquee_bg_color'], Colors.orange);
    final textColor = _parseColor(updateInfo['marquee_text_color'], Colors.white);

    return GestureDetector(
      onTap: () {
        final targetType = updateInfo['marquee_target_type'];
        final targetId = updateInfo['marquee_target_id'];
        UpdateService().handlePromotionTap(context, targetType, targetId);
      },
      child: Container(
        height: 35,
        color: bgColor,
        child: Marquee(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          scrollAxis: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          blankSpace: 20.0,
          velocity: 30.0,
          pauseAfterRound: const Duration(seconds: 1),
          startPadding: 10.0,
          accelerationDuration: const Duration(seconds: 1),
          accelerationCurve: Curves.linear,
          decelerationDuration: const Duration(milliseconds: 500),
          decelerationCurve: Curves.easeOut,
        ),
      ),
    );
  }

  Color _parseColor(dynamic colorValue, Color fallback) {
    String? colorStr = colorValue?.toString();
    if (colorStr == null || !colorStr.startsWith('#')) return fallback;
    try {
      final hexColor = colorStr.replaceFirst('#', 'ff');
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return fallback;
    }
  }
}
