import '../local/hive_service.dart';
import '../models/note_model.dart';

class NotesRepository {
  final box = HiveService.notes;

  List<NoteModel> getAllNotes() {
  return box.values
      .where(
        (note) => !note.isDeleted,
      )
      .toList();
}

  Future<void> addNote(NoteModel note) async {
    await box.put(note.id, note);
  }

Future<void> updateNote(NoteModel note) async {
  await box.put(note.id, note);
}

  Future<void> deleteNote(String id) async {
    await box.delete(id);
  }
  NoteModel? getNoteById(
  String id,
) {
  return box.get(id);
}

}