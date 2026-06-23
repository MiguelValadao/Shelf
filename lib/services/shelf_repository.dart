import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';
import '../models/quote.dart';
import '../models/user_book.dart';
import 'supabase_service.dart';

class ShelfRepository {
  final SupabaseClient _client = SupabaseService.client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }
    return user.id;
  }

  /// Busca toda a estante do usuário logado, opcionalmente filtrando por status.
  Future<List<UserBook>> getShelf({ReadingStatus? statusFilter}) async {
    var query = _client.from('shelf_view').select().eq('user_id', _userId);

    if (statusFilter != null) {
      query = query.eq('status', statusFilter.value);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((row) => UserBook.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<UserBook> getUserBookById(String userBookId) async {
    final response = await _client
        .from('shelf_view')
        .select()
        .eq('user_book_id', userBookId)
        .single();
    return UserBook.fromJson(response);
  }

  /// Adiciona um livro à estante. Faz upsert em `books` (evita duplicar pelo
  /// ISBN) e depois cria o vínculo em `user_books`.
  Future<String> addBookToShelf({
    required Book book,
    ReadingStatus status = ReadingStatus.toRead,
  }) async {
    Map<String, dynamic> bookRow;

    if (book.isbn != null && book.isbn!.isNotEmpty) {
      bookRow = await _client
          .from('books')
          .upsert(book.toJson(), onConflict: 'isbn')
          .select()
          .single();
    } else {
      // Sem ISBN (cadastro 100% manual de um livro sem código) -> insert simples
      bookRow = await _client.from('books').insert(book.toJson()).select().single();
    }

    final userBookRow = await _client
        .from('user_books')
        .insert({
          'user_id': _userId,
          'book_id': bookRow['id'],
          'status': status.value,
          'total_pages': book.pageCount,
        })
        .select()
        .single();

    return userBookRow['id'] as String;
  }

  Future<void> updateStatus(String userBookId, ReadingStatus status) async {
    await _client
        .from('user_books')
        .update({'status': status.value})
        .eq('id', userBookId);
  }

  Future<void> updateProgress({
    required String userBookId,
    required int currentPage,
    int? totalPages,
  }) async {
    final data = <String, dynamic>{'current_page': currentPage};
    if (totalPages != null) {
      data['total_pages'] = totalPages;
    }
    await _client.from('user_books').update(data).eq('id', userBookId);
  }

  Future<void> updateRating(String userBookId, int rating) async {
    await _client
        .from('user_books')
        .update({'rating': rating})
        .eq('id', userBookId);
  }

  Future<void> removeFromShelf(String userBookId) async {
    await _client.from('user_books').delete().eq('id', userBookId);
  }

  // ---------------- Quotes ----------------

  Future<List<Quote>> getQuotes(String userBookId) async {
    final response = await _client
        .from('quotes')
        .select()
        .eq('user_book_id', userBookId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((row) => Quote.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> addQuote(Quote quote) async {
    await _client.from('quotes').insert(quote.toJson());
  }

  Future<void> deleteQuote(String quoteId) async {
    await _client.from('quotes').delete().eq('id', quoteId);
  }
}
