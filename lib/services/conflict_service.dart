import '../data/local/hive_service.dart';
import '../data/models/note_model.dart';
import '../data/remote/notes_api_service.dart';

class ConflictService {

  final NotesApiService api =
      NotesApiService();

  Future<void> keepLocal(
      NoteModel note) async {

    await api.updateNote(
      note.id,
      note.toJson(),
    );

    note.syncStatus =
        'synced';

    note.serverTitle = null;
    note.serverBody = null;

    note.lastSyncedAt =
        DateTime.now();

    await note.save();

    // Clear any queue items for this note
    for (final qItem in HiveService.syncQueue.values.toList()) {
      if (qItem.noteId == note.id) {
        await qItem.delete();
      }
    }
  }

  Future<void> keepServer(
    NoteModel note) async {

  note.title =
      note.serverTitle ?? '';

  note.body =
      note.serverBody ?? '';

  note.syncStatus =
      'synced';

  note.serverTitle = null;
  note.serverBody = null;

  note.lastSyncedAt =
      DateTime.now();

  await note.save();

  // Clear any queue items for this note
  for (final qItem in HiveService.syncQueue.values.toList()) {
    if (qItem.noteId == note.id) {
      await qItem.delete();
    }
  }
}
}