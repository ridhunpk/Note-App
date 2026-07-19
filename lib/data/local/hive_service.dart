import 'package:hive_flutter/hive_flutter.dart';

import '../models/note_model.dart';
import '../models/sync_queue_model.dart';
class HiveService {
  static const notesBox = 'notes_box';
  static const syncBox = 'sync_box';
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(NoteModelAdapter());

    await Hive.openBox<NoteModel>(notesBox);
    Hive.registerAdapter(
  SyncQueueModelAdapter(),
  
);
await Hive.openBox<SyncQueueModel>(
  syncBox,
);
  }
  static Box<SyncQueueModel> get syncQueue =>
    Hive.box<SyncQueueModel>(syncBox);

  static Box<NoteModel> get notes =>
      Hive.box<NoteModel>(notesBox);
}