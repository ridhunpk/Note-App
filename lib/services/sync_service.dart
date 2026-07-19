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

    // 1. Pull server notes first to detect conflicts
    try {
      await _pullServerNotes();
    } catch (e) {
      errors.add('pull: $e');
    }

    final queue = HiveService.syncQueue.values.toList();

    // 2. Process pending local updates (skipping those marked as conflict)
    for (final item in queue) {
      try {
        final notesBox = HiveService.notes;
        final note = notesBox.get(item.noteId);
        
        // If there's a conflict, do not push. Wait for user resolution.
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
          // POST to server — server assigns its own numeric ID
          final serverId = await api.createNote(note.toJson());

          // ── Key Fix: Re-key the local Hive entry with the server-assigned ID ──
          // Without this, updates/deletes use the local UUID → 404 on server,
          // and _pullServerNotes creates a duplicate entry for the server ID.
          final oldLocalId = note.id;

          note.id = serverId;
          note.syncStatus = 'synced';
          note.lastSyncedAt = DateTime.now();

          // Delete old UUID-keyed entry, save with server ID as key
          await notesBox.delete(oldLocalId);
          await notesBox.put(serverId, note);

          // Also update any remaining queue items that still reference the old UUID
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
          // note.id is now the server-assigned ID (after create re-keying)
          await api.updateNote(note.id, note.toJson());
          note.syncStatus = 'synced';
          note.lastSyncedAt = DateTime.now();
          await note.save();
        }
        await item.delete();
        break;

      case 'delete':
        // Use item.noteId in case it's still a UUID that was never synced
        try {
          await api.deleteNote(item.noteId);
        } catch (_) {
          // If 404, the note doesn't exist on server — still safe to delete locally
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

    // Delete local notes that were deleted on the server (only if not pending local modifications)
    for (final localNote in notesBox.values.toList()) {
      if (localNote.syncStatus != 'pending' && !serverIds.contains(localNote.id)) {
        await notesBox.delete(localNote.id);
      }
    }

    for (final json in serverNotes) {
      final serverNote = NoteModel.fromJson(json);
      final localNote = notesBox.get(serverNote.id);

      if (localNote == null) {
        // Truly new note from server — save it locally
        await notesBox.put(serverNote.id, serverNote);
        continue;
      }

      await _detectConflict(localNote, serverNote);
    }
  }

  Future<void> _detectConflict(NoteModel local, NoteModel server) async {
    // 1. Short-circuit: If content is already identical, no conflict exists.
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
      // Genuine conflict — store server version for user to resolve
      local.syncStatus = 'conflict';
      local.serverTitle = server.title;
      local.serverBody = server.body;
      await local.save();
      return;
    }

    if (localModified && !serverModified) {
      // Only local was modified — do nothing, let the queue processor push it
      return;
    }

    // No conflict, and local was not modified but server was — update local with server data
    local.title = server.title;
    local.body = server.body;
    local.updatedAt = server.updatedAt;
    local.syncStatus = 'synced';
    local.serverTitle = null;
    local.serverBody = null;

    // Clock-skew guard: Ensure lastSyncedAt is always strictly after local.updatedAt
    final now = DateTime.now();
    local.lastSyncedAt = local.updatedAt.isAfter(now)
        ? local.updatedAt.add(const Duration(seconds: 1))
        : now;
        
    await local.save();
  }
}