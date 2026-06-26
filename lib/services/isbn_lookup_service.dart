import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/book.dart';

class IsbnLookupException implements Exception {
  final String message;
  IsbnLookupException(this.message);

  @override
  String toString() => message;
}

class IsbnLookupService {
  static const _googleBooksUrl =
      'https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}&key={apiKey}';

  Future<Book> lookup(String isbn) async {
    final cleanIsbn = isbn.replaceAll('-', '').replaceAll(' ', '').trim();

    final volumeInfo = await _fetchVolumeInfo(cleanIsbn);
    if (volumeInfo == null) {
      throw IsbnLookupException('Livro não encontrado para o ISBN $cleanIsbn.');
    }

    final title = volumeInfo['title'] as String? ?? 'Título não encontrado';

    final authors = (volumeInfo['authors'] as List<dynamic>?)
            ?.map((a) => a.toString())
            .toList() ??
        [];

    final rawCover = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final coverUrl = rawCover?['thumbnail'] as String?;

    return Book(
      isbn: cleanIsbn,
      title: title,
      authors: authors,
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      coverUrl: coverUrl,
      description: volumeInfo['description'] as String?,
      source: 'google_books',
    );
  }

  Future<Map<String, dynamic>?> _fetchVolumeInfo(String isbn) async {
    final uri = Uri.parse(
      _googleBooksUrl
          .replaceAll('{isbn}', isbn)
          .replaceAll('{apiKey}', AppConfig.googleBooksApiKey),
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return null;
      final first = items[0] as Map<String, dynamic>;
      return first['volumeInfo'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
