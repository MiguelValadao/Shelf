import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class IsbnLookupException implements Exception {
  final String message;
  IsbnLookupException(this.message);

  @override
  String toString() => message;
}

class IsbnLookupService {
  static const _openLibraryUrl = 'https://openlibrary.org/isbn/{isbn}.json';
  static const _authorUrl = 'https://openlibrary.org{author_key}.json';
  static const _coverUrl = 'https://covers.openlibrary.org/b/isbn/{isbn}-L.jpg';

  /// Consulta a Open Library diretamente pelo ISBN (sem backend Python).
  Future<Book> lookup(String isbn) async {
    final cleanIsbn = isbn.replaceAll('-', '').replaceAll(' ', '').trim();

    final bookData = await _fetchBookData(cleanIsbn);
    if (bookData == null) {
      throw IsbnLookupException('Livro não encontrado para o ISBN $cleanIsbn.');
    }

    final authors = await _fetchAuthors(bookData);

    final title = bookData['title'] as String? ?? 'Título não encontrado';

    var description = bookData['description'];
    if (description is Map) {
      description = description['value'] as String?;
    }

    return Book(
      isbn: cleanIsbn,
      title: title,
      authors: authors,
      publisher: _parseList(bookData['publishers']),
      publishedDate: bookData['publish_date'] as String?,
      pageCount: bookData['number_of_pages'] as int?,
      coverUrl: _coverUrl.replaceAll('{isbn}', cleanIsbn),
      description: description as String?,
      source: 'open_library',
    );
  }

  Future<Map<String, dynamic>?> _fetchBookData(String isbn) async {
    final uri = Uri.parse(_openLibraryUrl.replaceAll('{isbn}', isbn));
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _fetchAuthors(Map<String, dynamic> bookData) async {
    final authorRefs = bookData['authors'] as List<dynamic>?;
    if (authorRefs == null || authorRefs.isEmpty) return [];

    final names = <String>[];
    for (final ref in authorRefs) {
      final key = (ref as Map)['key'] as String?;
      if (key == null) continue;
      try {
        final uri = Uri.parse(_authorUrl.replaceAll('{author_key}', key));
        final response = await http.get(uri).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final authorData = jsonDecode(utf8.decode(response.bodyBytes));
          final name = authorData['name'] as String?;
          if (name != null && name.isNotEmpty) names.add(name);
        }
      } catch (_) {}
    }
    return names;
  }

  String? _parseList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().join(', ');
    }
    return value as String?;
  }
}
