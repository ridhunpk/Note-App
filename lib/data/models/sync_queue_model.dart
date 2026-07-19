import 'package:hive/hive.dart';

part 'sync_queue_model.g.dart';

@HiveType(typeId: 1)
class SyncQueueModel extends HiveObject {

  @HiveField(0)
  String noteId;

  @HiveField(1)
  String operation;

  SyncQueueModel({
    required this.noteId,
    required this.operation,
  });
}