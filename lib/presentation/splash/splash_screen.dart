import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// Фирменный сплэш-экран.
///
/// На тёмном фоне проявляются логотип и название приложения. По завершении
/// анимации вызывается [onFinished], после чего приложение переходит к
/// онбордингу или домашнему экрану.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(seconds: 5),
  });

  /// Вызывается один раз по завершении показа сплэша.
  final VoidCallback onFinished;

  /// Общая длительность показа (по умолчанию 5 секунд).
  final Duration duration;

  /// Верхний (основной) цвет тёмного фона.
  static const Color backgroundTop = Color(0xFF0B1F33);

  /// Нижний (световой центр радиального градиента) цвет фона.
  static const Color backgroundBottom = Color(0xFF163E63);

  /// Золотой акцент логотипа.
  static const Color accent = Color(0xFFD89030);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished();
        }
      });

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _glowOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _nameOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreen.backgroundTop,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              SplashScreen.backgroundBottom,
              SplashScreen.backgroundTop,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: _GlowLogo(glowOpacity: _glowOpacity),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _nameOpacity,
                child: SlideTransition(
                  position: _nameSlide,
                  child: const Text(
                    'Своё дело',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontFamilyFallback: AppFonts.interFallback,
                      fontSize: 34,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Логотип с мягким золотым свечением, нарастающим по мере появления.
class _GlowLogo extends StatelessWidget {
  const _GlowLogo({required this.glowOpacity});

  final Animation<double> glowOpacity;

  static const double _size = 148;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowOpacity,
      builder: (context, child) {
        return Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: SplashScreen.accent.withValues(
                  alpha: 0.28 * glowOpacity.value,
                ),
                blurRadius: 48,
                spreadRadius: 6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Image.asset(
          'assets/branding/logo_tile.png',
          width: _size,
          height: _size,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.shield, size: 72, color: SplashScreen.accent),
        ),
      ),
    );
  }
}
