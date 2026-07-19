import 'package:note_app/data/models/note_model.dart';

abstract class NotesEvent {}

class LoadNotes extends NotesEvent {}

class AddNote extends NotesEvent {
  final String title;
  final String body;

  AddNote(this.title, this.body);
}

class DeleteNote extends NotesEvent {
  final String id;

  DeleteNote(this.id);
}

class UpdateNote extends NotesEvent {
  final NoteModel note;

  UpdateNote(this.note);
}
