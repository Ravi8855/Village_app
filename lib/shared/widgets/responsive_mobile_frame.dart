import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';

/// Wraps the application in an authentic, sleek smartphone frame when viewed
/// on wide desktop/web screens, while seamlessly filling the entire display
/// on mobile devices or narrow browser viewports.
class ResponsiveMobileFrame extends StatefulWidget {
  const ResponsiveMobileFrame({
    super.key,
    required this.child,
    this.phoneWidth = 412.0,
    this.phoneHeight = 860.0,
  });

  final Widget child;
  final double phoneWidth;
  final double phoneHeight;

  @override
  State<ResponsiveMobileFrame> createState() => _ResponsiveMobileFrameState();
}

class _ResponsiveMobileFrameState extends State<ResponsiveMobileFrame> {
  bool _forceMobileFrame = true;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // If viewport is already phone-sized (<= 500px) or user turned off frame:
        final isMobileViewport = screenWidth <= 500;
        if (isMobileViewport || !_forceMobileFrame) {
          return widget.child;
        }

        // On desktop/tablet, calculate phone frame dimensions
        final double phoneW = widget.phoneWidth.clamp(360.0, screenWidth - 32.0);
        final double availableH = screenHeight - 60.0;
        final double phoneH = widget.phoneHeight.clamp(580.0, availableH > 600.0 ? availableH : screenHeight);

        final timeFormatted = DateFormat('h:mm').format(_currentTime);

        return Scaffold(
          backgroundColor: const Color(0xFF111714),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1A14),
                  Color(0xFF14221B),
                  Color(0xFF0C1410),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top desktop toolbar with branding and frame toggle
                Positioned(
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.smartphone_rounded,
                          size: 16,
                          color: Color(0xFF81C784),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mobile Preview · Naganoor Village App',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => setState(() => _forceMobileFrame = !_forceMobileFrame),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _forceMobileFrame ? Icons.fullscreen : Icons.stay_current_portrait,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _forceMobileFrame ? 'Full Width' : 'Phone View',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Centered Realistic Smartphone Frame
                Center(
                  child: Container(
                    width: phoneW,
                    height: phoneH,
                    margin: const EdgeInsets.only(top: 36, bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: const Color(0xFF2A3A31),
                        width: 4.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 2,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                          blurRadius: 60,
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Column(
                        children: [
                          // Realistic Simulated Mobile Status Bar
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: AppColors.sand,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Time
                                Text(
                                  timeFormatted,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.soil,
                                    letterSpacing: -0.2,
                                  ),
                                ),

                                // Camera punch-hole / Dynamic island pill
                                Container(
                                  width: 72,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2822),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F1A14),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Status icons: 5G, Wi-Fi, Battery
                                const Row(
                                  children: [
                                    Icon(Icons.network_cell_rounded, size: 14, color: AppColors.soil),
                                    SizedBox(width: 4),
                                    Icon(Icons.wifi_rounded, size: 14, color: AppColors.soil),
                                    SizedBox(width: 4),
                                    Icon(Icons.battery_5_bar_rounded, size: 16, color: AppColors.soil),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // The actual app content constrained to mobile viewport
                          Expanded(
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                size: Size(phoneW, phoneH - 38 - 18),
                                padding: EdgeInsets.zero,
                                viewPadding: EdgeInsets.zero,
                              ),
                              child: widget.child,
                            ),
                          ),

                          // Bottom home gesture bar
                          Container(
                            height: 18,
                            alignment: Alignment.center,
                            color: AppColors.sand,
                            child: Container(
                              width: 120,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.soil.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
