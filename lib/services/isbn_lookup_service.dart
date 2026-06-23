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
  /// Consulta o backend Python, que por sua vez busca em
  /// Google Books / Open Library (com cache no Supabase).
  Future<Book> lookup(String isbn) async {
    final cleanIsbn = isbn.replaceAll('-', '').replaceAll(' ', '').trim();
    final uri = Uri.parse('${AppConfig.backendBaseUrl}/api/books/lookup')
        .replace(queryParameters: {'isbn': cleanIsbn});

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) {
      throw IsbnLookupException(
        'Livro não encontrado para o ISBN $cleanIsbn. Tente o cadastro manual.',
      );
    }

    if (response.statusCode != 200) {
      throw IsbnLookupException(
        'Erro ao consultar o livro (status ${response.statusCode}). Tente novamente.',
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    return Book(
      isbn: data['isbn'] as String?,
      title: data['title'] as String? ?? 'Título não encontrado',
      authors: (data['authors'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      publisher: data['publisher'] as String?,
      publishedDate: data['published_date'] as String?,
      pageCount: data['page_count'] as int?,
      coverUrl: data['cover_url'] as String?,
      description: data['description'] as String?,
      source: data['source'] as String? ?? 'unknown',
    );
  }
}
