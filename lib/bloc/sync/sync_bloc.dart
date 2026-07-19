import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/sync_service.dart';
import '../notes/notes_bloc.dart';
import '../notes/notes_event.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService syncService;
  final NotesBloc notesBloc;

  SyncBloc(this.syncService, this.notesBloc) : super(const SyncState()) {
    on<StartSync>(_startSync);
  }

  Future<void> _startSync(
    StartSync event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, error: null));

    try {
      await syncService.sync();

      emit(SyncState(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        error: "Something went wrong during sync. Please try again later.",
      ));
    }

    // Always reload notes after sync (success or partial)
    notesBloc.add(LoadNotes());
  }
}