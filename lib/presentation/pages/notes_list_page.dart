import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../bloc/notes/notes_bloc.dart';
import '../../bloc/notes/notes_event.dart';
import '../../bloc/notes/notes_state.dart';
import '../../bloc/sync/sync_bloc.dart';
import '../../bloc/sync/sync_event.dart';
import '../../bloc/sync/sync_state.dart';
import '../widgets/sync_status_chip.dart';
import 'add_note_page.dart';
import 'conflict_resolution_page.dart';
import 'edit_note_page.dart';

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/connectivity_service.dart';

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription? _connectivitySubscription;
  bool? _wasOnline;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = _connectivityService.stream.listen((results) {
      if (!mounted) return;
      final isOnline = results.any((r) => r != ConnectivityResult.none);

      if (_wasOnline != null && isOnline != _wasOnline) {
        // Clear any current snackbars immediately to avoid queueing delays
        ScaffoldMessenger.of(context).clearSnackBars();

        if (isOnline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1A3A2A),
              content: Row(
                children: [
                  const Icon(Icons.wifi_rounded, color: Color(0xFF4ADE80), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Back online. Syncing changes...',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4ADE80),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF3A1A1A),
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF5C5C), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Connection lost. Working offline.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF5C5C),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
      _wasOnline = isOnline;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (prev, curr) => curr.error != null && prev.error != curr.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF5C5C), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.error!.replaceFirst('Exception: ', ''),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        appBar: _buildAppBar(context),
        body: BlocBuilder<NotesBloc, NotesState>(
          builder: (context, state) {
            final notes = state.notes;
            if (notes.isEmpty) return _buildEmptyState();
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _NoteCard(
                  key: ValueKey(note.id),
                  title: note.title,
                  body: note.body,
                  updatedAt: note.updatedAt,
                  syncStatus: note.syncStatus,
                  onTap: () {
                    if (note.syncStatus == 'conflict') {
                      Navigator.push(
                        context,
                        _slideRoute(ConflictResolutionPage(note: note)),
                      );
                    } else {
                      Navigator.push(
                        context,
                        _slideRoute(EditNotePage(note: note)),
                      );
                    }
                  },
                  onDelete: () {
                    context.read<NotesBloc>().add(DeleteNote(note.id));
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: _AnimatedFab(
          onPressed: () => Navigator.push(
            context,
            _slideRoute(const AddNotePage()),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0D0F14),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Notes',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE8EAED),
            ),
          ),
          BlocBuilder<NotesBloc, NotesState>(
            builder: (context, state) => Text(
              '${state.notes.length} note${state.notes.length == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF8B8FA8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      actions: [
        BlocBuilder<SyncBloc, SyncState>(
          builder: (context, state) {
            if (state.isSyncing) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2334),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Syncing...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9D97FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return _SyncButton(
              lastSyncedAt: state.lastSyncedAt,
              onSync: () => context.read<SyncBloc>().add(StartSync()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFF2A2F45),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2334),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF2A2F45)),
            ),
            child: const Icon(
              Icons.note_alt_outlined,
              size: 48,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE8EAED),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first note',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF8B8FA8),
            ),
          ),
        ],
      ),
    );
  }

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}

// ─── Note Card ───────────────────────────────────────────────────────────────

class _NoteCard extends StatefulWidget {
  final String title;
  final String body;
  final DateTime updatedAt;
  final String syncStatus;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    super.key,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.syncStatus,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.syncStatus) {
      case 'conflict':
        return const Color(0xFFFF5C5C).withValues(alpha: 0.4);
      case 'pending':
        return const Color(0xFFFBBF24).withValues(alpha: 0.3);
      default:
        return const Color(0xFF2A2F45);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${widget.title}_${widget.updatedAt}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Color(0xFFFF5C5C), size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFFF5C5C),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown: (_) => _hoverController.forward(),
          onTapUp: (_) {
            _hoverController.reverse();
            widget.onTap();
          },
          onTapCancel: () => _hoverController.reverse(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2334),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE8EAED),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SyncStatusChip(status: widget.syncStatus),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFFF5C5C),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E2334),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFF2A2F45)),
                            ),
                            title: Text(
                              'Delete Note?',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE8EAED),
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete this note?',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8B8FA8),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF8B8FA8),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onDelete();
                                },
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFFF5C5C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (widget.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF8B8FA8),
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: const Color(0xFF8B8FA8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(widget.updatedAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8B8FA8),
                      ),
                    ),
                    if (widget.syncStatus == 'conflict') ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Tap to resolve',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFFFF5C5C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

// ─── Sync Button ─────────────────────────────────────────────────────────────

class _SyncButton extends StatelessWidget {
  final DateTime? lastSyncedAt;
  final VoidCallback onSync;

  const _SyncButton({this.lastSyncedAt, required this.onSync});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSync,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2334),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2F45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF9D97FF)),
            const SizedBox(width: 5),
            Text(
              lastSyncedAt == null ? 'Sync' : 'Synced',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9D97FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated FAB ────────────────────────────────────────────────────────────

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedFab({required this.onPressed});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: RotationTransition(
              turns: _rotateAnim,
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
