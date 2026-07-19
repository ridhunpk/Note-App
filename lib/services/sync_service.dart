import '../data/local/hive_service.dart';
import '../data/models/note_model.dart';
import '../data/models/sync_queue_model.dart';
import '../data/remote/notes_api_service.dart';

class SyncService {
  final NotesApiService api = NotesApiService();

  static bool shouldFlagConflict(NoteModel local, NoteModel server) {
    final localCheckpoint = local.lastSyncedAt;
    final hasLocalChange = local.syncStatus == 'pending' ||
        local.syncStatus == 'conflict' ||
        localCheckpoint == null ||
        local.updatedAt.isAfter(localCheckpoint);

    final hasServerChange = localCheckpoint == null ||
        server.updatedAt.isAfter(localCheckpoint);

    if (!hasLocalChange && !hasServerChange) {
      return false;
    }

    if (!hasLocalChange) {
      return false;
    }

    if (!hasServerChange) {
      return false;
    }

    return true;
  }

  Future<void> sync() async {
    final List<String> errors = [];

    try {
      await _pullServerNotes();
    } catch (e) {
      errors.add('pull: $e');
    }

    final queue = HiveService.syncQueue.values.toList();

    for (final item in queue) {
      try {
        final notesBox = HiveService.notes;
        final note = notesBox.get(item.noteId);
        if (note != null && note.syncStatus == 'conflict') {
          continue;
        }

        await _processQueueItem(item);
      } catch (e) {
        errors.add('${item.operation}(${item.noteId}): $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception('Sync completed with errors:\n${errors.join('\n')}');
    }
  }

  Future<void> _processQueueItem(SyncQueueModel item) async {
    final notesBox = HiveService.notes;
    final note = notesBox.get(item.noteId);

    switch (item.operation) {
      case 'create':
        if (note != null) {
          final serverId = await api.createNote(note.toJson());
          final oldLocalId = note.id;

          note.id = serverId;
          note.syncStatus = 'synced';
          note.lastSyncedAt = DateTime.now();
          await notesBox.delete(oldLocalId);
          await notesBox.put(serverId, note);
          for (final qItem in HiveService.syncQueue.values.toList()) {
            if (qItem.noteId == oldLocalId && qItem != item) {
              qItem.noteId = serverId;
              await qItem.save();
            }
          }
        }
        await item.delete();
        break;

      case 'update':
        if (note != null) {
          await api.updateNote(note.id, note.toJson());
          note.syncStatus = 'synced';
          note.lastSyncedAt = DateTime.now();
          await note.save();
        }
        await item.delete();
        break;

      case 'delete':
        try {
          await api.deleteNote(item.noteId);
        } catch (_) {
        }
        await notesBox.delete(item.noteId);
        await item.delete();
        break;
    }
  }

  Future<void> _pullServerNotes() async {
    final serverNotes = await api.getNotes();
    final notesBox = HiveService.notes;

    final serverIds = serverNotes.map((json) => json['id'].toString()).toSet();
    for (final localNote in notesBox.values.toList()) {
      if (localNote.syncStatus != 'pending' && !serverIds.contains(localNote.id)) {
        await notesBox.delete(localNote.id);
      }
    }

    for (final json in serverNotes) {
      final serverNote = NoteModel.fromJson(json);
      final localNote = notesBox.get(serverNote.id);

      if (localNote == null) {
        await notesBox.put(serverNote.id, serverNote);
        continue;
      }

      await _detectConflict(localNote, serverNote);
    }
  }

  Future<void> _detectConflict(NoteModel local, NoteModel server) async {
    if (local.title == server.title && local.body == server.body) {
      local.syncStatus = 'synced';
      local.serverTitle = null;
      local.serverBody = null;
      local.lastSyncedAt = DateTime.now();
      await local.save();
      return;
    }

    final bool localModified = local.syncStatus == 'pending' ||
        local.syncStatus == 'conflict' ||
        local.lastSyncedAt == null ||
        local.updatedAt.isAfter(local.lastSyncedAt!);
    final bool serverModified = local.lastSyncedAt == null ||
        server.updatedAt.isAfter(local.lastSyncedAt!);

    if (localModified && serverModified) {
      local.syncStatus = 'conflict';
      local.serverTitle = server.title;
      local.serverBody = server.body;
      local.serverUpdatedAt = server.updatedAt;
      await local.save();
      return;
    }

    if (localModified && !serverModified) {
      return;
    }

    local.title = server.title;
    local.body = server.body;
    local.updatedAt = server.updatedAt;
    local.syncStatus = 'synced';
    local.serverTitle = null;
    local.serverBody = null;
    local.lastSyncedAt = server.updatedAt;

    try {
      print('sync:_detectConflict timestamps - local.updatedAt=${local.updatedAt.toIso8601String()}, local.lastSyncedAt=${local.lastSyncedAt?.toIso8601String()}, server.updatedAt=${server.updatedAt.toIso8601String()}');
    } catch (_) {
    }

    await local.save();
  }
}