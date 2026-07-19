import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String syncStatus;

  @HiveField(5)
  bool isDeleted;
  @HiveField(6)
  DateTime? lastSyncedAt;
  @HiveField(7)
  String? serverTitle;

  @HiveField(8)
  String? serverBody;

  NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.syncStatus,
    this.isDeleted = false,
    this.lastSyncedAt,
    this.serverTitle,
    this.serverBody,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      syncStatus: 'synced',
      lastSyncedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
