import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// CONFETTI CELEBRATION — Telegram-style celebration overlay
// Использование:
//   ConfettiCelebration.show(context, type: CelebrationTyp.bidAccepted)
// ═══════════════════════════════════════════════════════════════

enum CelebrationType {
  bidAccepted,    // Получили заказ! 🎉
  becomeMaster,   // Стали мастером! 🏆
  firstOrder,     // Первый заказ! 🌟
  taskCompleted,  // Задание выполнено! ✅
}

class ConfettiCelebration {
  /// Показывает конфетти + карточку поздравления
  static void show(BuildContext context, {required CelebrationType type}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationOverlay(
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

// ─── Данные для каждого типа поздравления ───────────────────
class _CelebData {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _CelebData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  static _CelebData from(CelebrationType type) {
    switch (type) {
      case CelebrationType.bidAccepted:
        return const _CelebData(
          emoji: '🎉',
          title: 'Заказ получен!',
          subtitle: 'Клиент принял ваш отклик.\nПриступайте к работе!',
          gradient: [Color(0xFF00875A), Color(0xFF00C97B)],
        );
      case CelebrationType.becomeMaster:
        return const _CelebData(
          emoji: '🏆',
          title: 'Вы — Мастер!',
          subtitle: 'Добро пожаловать в команду\nпрофессионалов Hunar!',
          gradient: [Color(0xFFD4AC0D), Color(0xFFF4D03F)],
        );
      case CelebrationType.firstOrder:
        return const _CelebData(
          emoji: '🌟',
          title: 'Первый заказ!',
          subtitle: 'Вы разместили свой первый заказ.\nМастера уже видят его!',
          gradient: [Color(0xFF6C3483), Color(0xFFA855F7)],
        );
      case CelebrationType.taskCompleted:
        return const _CelebData(
          emoji: '✅',
          title: 'Задание выполнено!',
          subtitle: 'Отличная работа! Не забудьте\nоставить отзыв мастеру.',
          gradient: [Color(0xFF1A5276), Color(0xFF2E86C1)],
        );
    }
  }
}

// ─── Overlay-виджет ─────────────────────────────────────────
class _CelebrationOverlay extends StatefulWidget {
  final CelebrationType type;
  final VoidCallback onDismiss;

  const _CelebrationOverlay({required this.type, required this.onDismiss});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _confettiController;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _cardSlide;

  final List<_ConfettiParticle> _particles = [];
  final math.Random _rng = math.Random();

  static const int _particleCount = 80;

  @override
  void initState() {
    super.initState();

    // Card animation
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _cardSlide = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Generate particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_ConfettiParticle(rng: _rng));
    }

    _confettiController.forward();
    _cardController.forward();

    // Auto-dismiss after 3.5s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _cardController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final data = _CelebData.from(widget.type);

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        child: Stack(
          children: [
            // ── Confetti particles ──
            AnimatedBuilder(
              animation: _confettiController,
              builder: (_, __) {
                return CustomPaint(
                  size: size,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),

            // ── Celebration card ──
            Center(
              child: AnimatedBuilder(
                animation: _cardController,
                builder: (_, child) {
                  return FadeTransition(
                    opacity: _cardFade,
                    child: Transform.translate(
                      offset: Offset(0, _cardSlide.value),
                      child: ScaleTransition(
                        scale: _cardScale,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _CelebrationCard(data: data, onDismiss: _dismiss),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Карточка поздравления ────────────────────────────────────
class _CelebrationCard extends StatelessWidget {
  final _CelebData data;
  final VoidCallback onDismiss;

  const _CelebrationCard({required this.data, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: data.gradient.first.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: data.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji large
              Text(data.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),

              // Title
              Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                data.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Dismiss button
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'Отлично! 🚀',
                    style: TextStyle(
                      color: data.gradient.first,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

// ─── Конфетти-частица ────────────────────────────────────────
class _ConfettiParticle {
  final double x;      // start x (0..1)
  final double y;      // start y (0..0.5 — above visible)
  final double size;
  final double speed;
  final double drift;   // horizontal drift
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final bool isCircle;

  static const List<Color> _colors = [
    Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4),
    Color(0xFF45B7D1), Color(0xFF96E6A1), Color(0xFFDDA0DD),
    Color(0xFFFF9F43), Color(0xFF00D2D3), Color(0xFFFF6CAE),
    Color(0xFFFECA57), Color(0xFF48DBFB),
  ];

  _ConfettiParticle({required math.Random rng})
      : x = rng.nextDouble(),
        y = -rng.nextDouble() * 0.3,
        size = 6 + rng.nextDouble() * 10,
        speed = 0.25 + rng.nextDouble() * 0.45,
        drift = (rng.nextDouble() - 0.5) * 0.3,
        rotation = rng.nextDouble() * math.pi * 2,
        rotationSpeed = (rng.nextDouble() - 0.5) * 8,
        color = _colors[rng.nextInt(_colors.length)],
        isCircle = rng.nextBool();
}

// ─── CustomPainter ───────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress; // 0..1

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final p in particles) {
      final t = progress * p.speed * 2.5;
      // Gravity curve
      final fallY = p.y + t + 0.5 * t * t * 0.8;
      final driftX = p.x + p.drift * progress;

      final px = driftX * size.width;
      final py = fallY * size.height;

      // Fade in at top, fade out at bottom
      double opacity = 1.0;
      if (fallY < 0.05) opacity = (fallY / 0.05).clamp(0, 1);
      if (fallY > 0.75) opacity = ((1.0 - fallY) / 0.25).clamp(0, 1);

      if (opacity <= 0 || py > size.height + 20) continue;

      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + p.rotationSpeed * progress);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        // Rectangle confetti
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
