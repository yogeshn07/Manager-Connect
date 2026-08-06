import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

// ── Grid topology overlay ─────────────────────────────────────────────────────
//
// A static CustomPainter that draws a lightweight abstract network topology
// inspired by grid integration diagrams — nodes connected by transmission paths.
//
// Intended placement: behind existing content on dark (navy) surfaces such as
// the splash screen and the welcome hero panel.
// Opacity values are kept very low so the overlay is felt, not read.

class MCGridOverlay extends StatelessWidget {
  const MCGridOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        painter: _GridTopologyPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _GridTopologyPainter extends CustomPainter {
  const _GridTopologyPainter();

  // Node positions as fractions of (width, height).
  // Arranged as a plausible 8-node network topology — not random.
  static const _nodes = [
    (0.10, 0.11), // A — top-left substation
    (0.44, 0.07), // B — top-center switching node
    (0.84, 0.19), // C — top-right endpoint
    (0.24, 0.36), // D — mid-left junction
    (0.67, 0.33), // E — mid-right junction
    (0.06, 0.60), // F — left edge node
    (0.50, 0.68), // G — center distribution node
    (0.89, 0.63), // H — right edge node
  ];

  // Adjacency list — each pair is an undirected edge.
  static const _edges = [
    (0, 1), // A-B  top horizontal
    (1, 2), // B-C  top right
    (0, 3), // A-D  left vertical
    (1, 3), // B-D  diagonal
    (1, 4), // B-E  diagonal
    (2, 4), // C-E  right side
    (3, 5), // D-F  left drop
    (3, 6), // D-G  center diagonal
    (4, 7), // E-H  right drop
    (6, 7), // G-H  bottom horizontal
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Convert relative positions to actual offsets
    final offsets = _nodes
        .map((n) => Offset(n.$1 * w, n.$2 * h))
        .toList();

    // Transmission lines — white at 5% opacity
    final linePaint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    for (final edge in _edges) {
      canvas.drawLine(offsets[edge.$1], offsets[edge.$2], linePaint);
    }

    // Nodes — white at 9% for primary nodes, 6% for secondary
    for (int i = 0; i < offsets.length; i++) {
      // Larger nodes: A (index 0), B (1), G (6) — junction / substation analogy
      final isPrimary = i == 0 || i == 1 || i == 6;
      final r = isPrimary ? 4.5 : 3.0;
      final opacity = isPrimary ? 0x17 : 0x0F; // ~9% or ~6%

      canvas.drawCircle(
        offsets[i],
        r,
        Paint()..color = Color.fromARGB(opacity, 255, 255, 255),
      );
    }

    // Amber accent dot — amber at 18% opacity — marks the central node (G)
    // This is the one point where the identity accent colour appears in the background.
    canvas.drawCircle(
      offsets[6],
      2.5,
      Paint()..color = const Color(0x2DFFB840),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── LIVE pill ─────────────────────────────────────────────────────────────────
//
// Signals that a data surface is receiving live updates (polls, challenges).
// Uses energyRed — the single identity signal colour added in Stage 1.

class MCLivePill extends StatelessWidget {
  const MCLivePill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x26CC1C22), // 15% opacity — visible on white card
        borderRadius: BorderRadius.circular(MCSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: MCColors.energyRed,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: MCTypography.overline.copyWith(color: MCColors.energyRed),
          ),
        ],
      ),
    );
  }
}

// ── Ambient identity background ──────────────────────────────────────────────
//
// Ultra-subtle ambient energy-red corner glow for top-level light backgrounds.
// Gradient centres land exactly at screen corners so diffusion reads as
// environmental light, not an obvious gradient blob.
// Max alpha: 0x1A (~10%) at the corner apex — invisible on white cards.

class MCAmbientIdentityBackground extends StatelessWidget {
  const MCAmbientIdentityBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Primary glow — top-right corner
        // Container offset so its centre lands at (screen_width, 0).
        Positioned(
          top: -300,
          right: -300,
          child: RepaintBoundary(
            child: Container(
              width: 600,
              height: 600,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x1ACC1C22), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // Secondary glow — bottom-left corner (softer)
        Positioned(
          bottom: -240,
          left: -240,
          child: RepaintBoundary(
            child: Container(
              width: 480,
              height: 480,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x0FCC1C22), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ── Grid section label ────────────────────────────────────────────────────────
//
// A subtle two-line header treatment for sections with network identity.
// Used selectively — not on every section.

class MCNetworkSectionLabel extends StatelessWidget {
  const MCNetworkSectionLabel({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: MCColors.energyRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: MCTypography.h3),
            if (subtitle != null)
              Text(
                subtitle!,
                style: MCTypography.caption
                    .copyWith(color: MCColors.textMuted, letterSpacing: 0.3),
              ),
          ],
        ),
      ],
    );
  }
}
