import 'package:dio/dio.dart';

class NotesApiService {
  final Dio dio = Dio();

  final String baseUrl =
      'https://6a5c584c64f700df5bd7f6d6.mockapi.io/notesapi/v1/notes';

  /// Creates a note on the server and returns the server-assigned ID.
  Future<String> createNote(Map<String, dynamic> noteData) async {
    // Strip the local UUID — let the server assign its own ID
    final payload = Map<String, dynamic>.from(noteData)..remove('id');
    final response = await dio.post(baseUrl, data: payload);
    return response.data['id'].toString();
  }

  Future<void> updateNote(
    String id,
    Map<String, dynamic> noteData,
  ) async {
    await dio.put(
      '$baseUrl/$id',
      data: noteData,
    );
  }

  Future<void> deleteNote(String id) async {
    await dio.delete('$baseUrl/$id');
  }

  Future<List<dynamic>> getNotes() async {
    final response = await dio.get(baseUrl);
    return response.data;
  }
}