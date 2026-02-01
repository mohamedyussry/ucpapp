import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/models/loyalty_model.dart';
import 'package:myapp/services/loyalty_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/loyalty_provider.dart';
import '../l10n/generated/app_localizations.dart';

class MyPointsScreen extends StatefulWidget {
  const MyPointsScreen({super.key});

  @override
  State<MyPointsScreen> createState() => _MyPointsScreenState();
}

class _MyPointsScreenState extends State<MyPointsScreen> {
  List<PointHistory> _pointHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final loyaltyProvider = Provider.of<LoyaltyProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isHistoryLoading = true;
    });

    try {
      await loyaltyProvider.initialize();
      final history = await LoyaltyService().getPointHistory();

      if (mounted) {
        setState(() {
          _pointHistory = history;
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyProvider = Provider.of<LoyaltyProvider>(context);
    final isLoading = loyaltyProvider.isLoading || _isHistoryLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.loyalty_rewards_title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcome_rewards,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLoyaltyCard(loyaltyProvider.loyaltyData),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.points_history,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadData,
                          child: Text(
                            l10n.refresh,
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildHistorySection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoyaltyCard(LoyaltyData? loyaltyData) {
    final NumberFormat formatter = NumberFormat('#,###');
    final points = loyaltyData?.pointsBalance ?? 0;
    final tier = loyaltyData?.tierName ?? 'Bronze';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8E8E8E),
            Color(0xFFE4A143),
          ], // Closer to image colors
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.loyalty_card_label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.medal,
                      color: Color(0xFFFFD700),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tier,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            l10n.current_points,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          Text(
            formatter.format(points),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.ucp_loyalty_program,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                l10n.active_account,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final l10n = AppLocalizations.of(context)!;
    if (_pointHistory.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          l10n.no_history_found,
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pointHistory.length,
      itemBuilder: (context, index) {
        final item = _pointHistory[index];
        final isEarn =
            item.operation == 'earn' || double.parse(item.points) > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isEarn
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEarn ? Icons.add_rounded : Icons.remove_rounded,
                  color: isEarn ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.operation.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      item.creationDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isEarn ? '+' : ''}${item.points} ${l10n.pts_suffix}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: isEarn ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
