import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/notes/notes_bloc.dart';
import '../../bloc/notes/notes_event.dart';
import '../../data/models/note_model.dart';
import '../../services/conflict_service.dart';

class ConflictResolutionPage extends StatefulWidget {
  final NoteModel note;

  const ConflictResolutionPage({super.key, required this.note});

  @override
  State<ConflictResolutionPage> createState() => _ConflictResolutionPageState();
}

class _ConflictResolutionPageState extends State<ConflictResolutionPage>
    with SingleTickerProviderStateMixin {
  final ConflictService _service = ConflictService();
  bool _isResolvingLocal = false;
  bool _isResolvingServer = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolveLocal() async {
    setState(() => _isResolvingLocal = true);
    try {
      await _service.keepLocal(widget.note);
      if (mounted) {
        context.read<NotesBloc>().add(LoadNotes()); // Bug fix: reload list
        _showSuccess('Local version kept & pushed to server');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResolvingLocal = false);
        _showError('Failed to resolve: $e');
      }
    }
  }

  Future<void> _resolveServer() async {
    setState(() => _isResolvingServer = true);
    try {
      await _service.keepServer(widget.note);
      if (mounted) {
        context.read<NotesBloc>().add(LoadNotes()); // Bug fix: reload list
        _showSuccess('Server version applied to local');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResolvingServer = false);
        _showError('Failed to resolve: $e');
      }
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF4ADE80), size: 18),
            const SizedBox(width: 8),
            Text(msg, style: GoogleFonts.inter(fontSize: 13)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFFF5C5C), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 13))),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F14),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2334),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: Color(0xFFE8EAED)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resolve Conflict',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFE8EAED),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2A2F45)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFF5C5C).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: Color(0xFFFF5C5C), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Both local and server versions were modified. Choose which version to keep.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFFF8A8A),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Local version card
            _VersionCard(
              label: 'LOCAL VERSION',
              labelColor: const Color(0xFF4ADE80),
              labelBg: const Color(0xFF1A3A2A),
              icon: Icons.phone_android_rounded,
              iconColor: const Color(0xFF4ADE80),
              title: widget.note.title,
              body: widget.note.body,
              borderColor: const Color(0xFF4ADE80).withValues(alpha: 0.3),
            ),

            const SizedBox(height: 8),

            // VS divider
            Row(
              children: [
                Expanded(
                    child: Divider(color: const Color(0xFF2A2F45))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2334),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2A2F45)),
                    ),
                    child: Text(
                      'VS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B8FA8),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                Expanded(
                    child: Divider(color: const Color(0xFF2A2F45))),
              ],
            ),

            const SizedBox(height: 8),

            // Server version card
            _VersionCard(
              label: 'SERVER VERSION',
              labelColor: const Color(0xFF9D97FF),
              labelBg: const Color(0xFF1E1A3A),
              icon: Icons.cloud_rounded,
              iconColor: const Color(0xFF9D97FF),
              title: widget.note.serverTitle ?? '(no server title)',
              body: widget.note.serverBody ?? '(no server content)',
              borderColor: const Color(0xFF9D97FF).withValues(alpha: 0.3),
            ),

            const SizedBox(height: 32),

            // Keep Local button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isResolvingLocal || _isResolvingServer)
                    ? null
                    : _resolveLocal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A2A),
                  foregroundColor: const Color(0xFF4ADE80),
                  side: const BorderSide(color: Color(0xFF4ADE80), width: 1.5),
                  disabledBackgroundColor: const Color(0xFF1A3A2A).withValues(alpha: 0.5),
                ),
                child: _isResolvingLocal
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4ADE80),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Keep My Version',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Keep Server button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: (_isResolvingLocal || _isResolvingServer)
                    ? null
                    : _resolveServer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9D97FF),
                  side: const BorderSide(color: Color(0xFF9D97FF), width: 1.5),
                  disabledForegroundColor:
                      const Color(0xFF9D97FF).withValues(alpha: 0.4),
                ),
                child: _isResolvingServer
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF9D97FF),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Use Server Version',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Version Card ─────────────────────────────────────────────────────────────

class _VersionCard extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Color labelBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Color borderColor;

  const _VersionCard({
    required this.label,
    required this.labelColor,
    required this.labelBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2334),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: labelColor),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE8EAED),
            ),
          ),

          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF8B8FA8),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}