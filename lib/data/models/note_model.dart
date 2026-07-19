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
  @HiveField(9)
  DateTime? serverUpdatedAt;

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
    this.serverUpdatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    final id = json['id']?.toString() ?? '';
    final title = json['title'] ?? '';
    final body = json['body'] ?? '';

    final rawUpdated = json['updatedAt'] ?? json['updateAt'] ?? json['createdAt'];
    final parsedUpdatedAt = _parseDate(rawUpdated);

    return NoteModel(
      id: id,
      title: title,
      body: body,
      updatedAt: parsedUpdatedAt,
      syncStatus: json['syncStatus'] ?? 'synced',
      lastSyncedAt: json['lastSyncedAt'] != null
          ? _parseDate(json['lastSyncedAt'])
          : DateTime.now(),
      serverTitle: json['title'],
      serverBody: json['body'],
      serverUpdatedAt: parsedUpdatedAt,
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
