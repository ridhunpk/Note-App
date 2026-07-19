import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/notes/notes_bloc.dart';
import '../../bloc/notes/notes_event.dart';
import '../../data/models/note_model.dart';

class EditNotePage extends StatefulWidget {
  final NoteModel note;

  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isSaving = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _bodyController = TextEditingController(text: widget.note.body);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    widget.note.title = title;
    widget.note.body = body;

    context.read<NotesBloc>().add(UpdateNote(widget.note));

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) Navigator.pop(context);
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
          'Edit Note',
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
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _FieldLabel('Title'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  color: const Color(0xFFE8EAED),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter note title...',
                  prefixIcon: Icon(
                    Icons.title_rounded,
                    color: Color(0xFF6C63FF),
                    size: 20,
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 20),

              _FieldLabel('Content'),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                maxLines: 10,
                style: GoogleFonts.inter(
                  color: const Color(0xFFE8EAED),
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  hintText: 'Write your note here...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 160),
                    child: Icon(
                      Icons.notes_rounded,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    disabledBackgroundColor:
                        const Color(0xFF6C63FF).withValues(alpha: 0.5),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Update Note',
                              style: GoogleFonts.inter(
                                fontSize: 15,
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF8B8FA8),
        letterSpacing: 0.8,
      ),
    );
  }
}