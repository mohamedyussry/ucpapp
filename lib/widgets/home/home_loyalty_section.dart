import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeLoyaltySection extends StatelessWidget {
  const HomeLoyaltySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<LoyaltyTier> tiers = [
      LoyaltyTier(
        name: l10n.tier_basic,
        points: '1',
        condition: '', // No condition for basic
        colors: [Colors.grey.shade600, Colors.grey.shade400],
      ),
      LoyaltyTier(
        name: l10n.tier_plus,
        points: '2',
        condition: l10n.condition_plus,
        colors: [const Color(0xFF8E8E8E), const Color(0xFFE4A143)],
      ),
      LoyaltyTier(
        name: l10n.tier_premium,
        points: '3',
        condition: l10n.condition_premium,
        colors: [const Color(0xFFE4A143), const Color(0xFFFFCC99)],
      ),
      LoyaltyTier(
        name: l10n.tier_elite,
        points: '4',
        condition: l10n.condition_elite,
        colors: [const Color(0xFFD487CC), const Color(0xFFE19FE0)],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            l10n.loyalty_program,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            height: 220,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
          ),
          items: tiers.map((tier) {
            return _buildLoyaltyCard(context, tier);
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoyaltyCard(BuildContext context, LoyaltyTier tier) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tier.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: tier.colors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle wave or decoration (can be ignored or simplified)
          Opacity(
            opacity: 0.1,
            child: Align(
              alignment: Alignment.center,
              child: const Icon(Icons.stars, size: 150, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.loyalty_card,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tier.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.boost_points,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      l10n.double_discounts,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.points_conversion(tier.points),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        l10n.points_value,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (tier.condition.isNotEmpty)
                    Expanded(
                      child: Text(
                        tier.condition,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LoyaltyTier {
  final String name;
  final String points;
  final String condition;
  final List<Color> colors;

  LoyaltyTier({
    required this.name,
    required this.points,
    required this.condition,
    required this.colors,
  });
}
