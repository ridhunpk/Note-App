import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/local/hive_service.dart';
import '../../data/models/sync_queue_model.dart';
import '../../data/remote/notes_api_service.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository repository;
  final NotesApiService api = NotesApiService();

  NotesBloc(this.repository) : super(NotesState([])) {
    on<LoadNotes>(_loadNotes);
    on<AddNote>(_addNote);
    on<UpdateNote>(_updateNote);
    on<DeleteNote>(_deleteNote);
  }

  void _loadNotes(LoadNotes event, Emitter<NotesState> emit) {
    emit(NotesState(repository.getAllNotes()));
  }

  Future<bool> _isOnlineAndQueueEmpty() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);
    final isQueueEmpty = HiveService.syncQueue.isEmpty;
    return isOnline && isQueueEmpty;
  }

  Future<void> _addNote(AddNote event, Emitter<NotesState> emit) async {
    final uuid = const Uuid().v4();
    final note = NoteModel(
      id: uuid,
      title: event.title,
      body: event.body,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    bool syncedDirectly = false;
    if (await _isOnlineAndQueueEmpty()) {
      try {
        final serverId = await api.createNote(note.toJson());
        note.id = serverId;
        note.syncStatus = 'synced';
        note.lastSyncedAt = DateTime.now();
        syncedDirectly = true;
      } catch (_) {
        // Fall back to offline queue if server request fails
      }
    }

    await repository.addNote(note);

    if (!syncedDirectly) {
      await HiveService.syncQueue.add(
        SyncQueueModel(noteId: note.id, operation: 'create'),
      );
    }
    add(LoadNotes());
  }

  Future<void> _updateNote(UpdateNote event, Emitter<NotesState> emit) async {
    event.note.updatedAt = DateTime.now();

    bool syncedDirectly = false;
    if (event.note.syncStatus == 'synced' && await _isOnlineAndQueueEmpty()) {
      try {
        await api.updateNote(event.note.id, event.note.toJson());
        event.note.syncStatus = 'synced';
        event.note.lastSyncedAt = DateTime.now();
        syncedDirectly = true;
      } catch (_) {
        // Fall back to offline queue if server request fails
      }
    }

    if (!syncedDirectly) {
      event.note.syncStatus = 'pending';
      final existsInQueue =
          HiveService.syncQueue.values.any((q) => q.noteId == event.note.id);
      if (!existsInQueue) {
        await HiveService.syncQueue.add(
          SyncQueueModel(noteId: event.note.id, operation: 'update'),
        );
      }
    }

    await repository.updateNote(event.note);
    add(LoadNotes());
  }

  Future<void> _deleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    final note = repository.getNoteById(event.id);
    if (note == null) return;

    bool deletedDirectly = false;
    if (note.syncStatus == 'synced' && await _isOnlineAndQueueEmpty()) {
      try {
        await api.deleteNote(note.id);
        await repository.deleteNote(note.id);
        deletedDirectly = true;
      } catch (_) {
        // Fall back to offline queue if server request fails
      }
    }

    if (!deletedDirectly) {
      note.isDeleted = true;
      note.syncStatus = 'pending';
      note.updatedAt = DateTime.now();
      await repository.updateNote(note);

      await HiveService.syncQueue.add(
        SyncQueueModel(noteId: note.id, operation: 'delete'),
      );
    }

    add(LoadNotes());
  }
}
