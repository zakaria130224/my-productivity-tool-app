import 'dart:async';

import 'package:flutter/material.dart';
import '../../home/screens/main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _rotAnim = Tween<double>(begin: -0.1, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _glowAnim = Tween<double>(begin: 0.0, end: 22.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _ctrl.repeat(reverse: true);

    // After a short delay navigate to MainLayout
    Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainLayout()));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final glow = _glowAnim.value;
                return Transform.rotate(
                  angle: _rotAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // animated glow ring
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // subtle gradient + animated shadow for glow
                            gradient: RadialGradient(
                              colors: [colorScheme.primary.withOpacity(0.14), Colors.transparent],
                              stops: const [0.0, 0.8],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.25),
                                blurRadius: glow,
                                spreadRadius: glow / 6,
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/logo_v2.png',
                          width: 160,
                          height: 160,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final glow = _glowAnim.value;
                return Text(
                  'My Rent Tracker',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        color: colorScheme.primary.withOpacity(0.95),
                        blurRadius: glow,
                      ),
                      Shadow(
                        color: colorScheme.primary.withOpacity(0.6),
                        blurRadius: glow / 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
