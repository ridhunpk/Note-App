import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SyncStatusChip extends StatefulWidget {
  final String status;

  const SyncStatusChip({super.key, required this.status});

  @override
  State<SyncStatusChip> createState() => _SyncStatusChipState();
}

class _SyncStatusChipState extends State<SyncStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.status == 'pending') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SyncStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == 'pending') {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _chipConfig(widget.status);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: config.bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing dot
              Opacity(
                opacity: widget.status == 'pending' ? _pulseAnim.value : 1.0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: config.dot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Icon(config.icon, size: 12, color: config.fg),
              const SizedBox(width: 4),
              Text(
                config.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: config.fg,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _ChipConfig _chipConfig(String status) {
    switch (status) {
      case 'synced':
        return _ChipConfig(
          bg: const Color(0xFF1A3A2A),
          fg: const Color(0xFF4ADE80),
          dot: const Color(0xFF4ADE80),
          icon: Icons.cloud_done_rounded,
          label: 'Synced',
        );
      case 'pending':
        return _ChipConfig(
          bg: const Color(0xFF2D2A14),
          fg: const Color(0xFFFBBF24),
          dot: const Color(0xFFFBBF24),
          icon: Icons.sync_rounded,
          label: 'Pending',
        );
      case 'conflict':
        return _ChipConfig(
          bg: const Color(0xFF3A1A1A),
          fg: const Color(0xFFFF5C5C),
          dot: const Color(0xFFFF5C5C),
          icon: Icons.warning_rounded,
          label: 'Conflict',
        );
      default:
        return _ChipConfig(
          bg: const Color(0xFF1E2334),
          fg: const Color(0xFF8B8FA8),
          dot: const Color(0xFF8B8FA8),
          icon: Icons.help_outline_rounded,
          label: status,
        );
    }
  }
}

class _ChipConfig {
  final Color bg, fg, dot;
  final IconData icon;
  final String label;
  const _ChipConfig({
    required this.bg,
    required this.fg,
    required this.dot,
    required this.icon,
    required this.label,
  });
}