import 'book.dart';

enum ReadingStatus { toRead, reading, finished, abandoned }

extension ReadingStatusX on ReadingStatus {
  String get value {
    switch (this) {
      case ReadingStatus.toRead:
        return 'to_read';
      case ReadingStatus.reading:
        return 'reading';
      case ReadingStatus.finished:
        return 'finished';
      case ReadingStatus.abandoned:
        return 'abandoned';
    }
  }

  String get label {
    switch (this) {
      case ReadingStatus.toRead:
        return 'Quero ler';
      case ReadingStatus.reading:
        return 'Lendo';
      case ReadingStatus.finished:
        return 'Lido';
      case ReadingStatus.abandoned:
        return 'Abandonado';
    }
  }

  static ReadingStatus fromValue(String value) {
    switch (value) {
      case 'reading':
        return ReadingStatus.reading;
      case 'finished':
        return ReadingStatus.finished;
      case 'abandoned':
        return ReadingStatus.abandoned;
      default:
        return ReadingStatus.toRead;
    }
  }
}

/// Representa uma linha da view `shelf_view` (user_books + books juntos).
class UserBook {
  final String userBookId;
  final String userId;
  final ReadingStatus status;
  final int currentPage;
  final int? totalPages;
  final int? rating;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final double progressPercent;
  final Book book;

  UserBook({
    required this.userBookId,
    required this.userId,
    required this.status,
    required this.currentPage,
    this.totalPages,
    this.rating,
    this.startedAt,
    this.finishedAt,
    required this.progressPercent,
    required this.book,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      userBookId: json['user_book_id'] as String,
      userId: json['user_id'] as String,
      status: ReadingStatusX.fromValue(json['status'] as String? ?? 'to_read'),
      currentPage: json['current_page'] as int? ?? 0,
      totalPages: json['total_pages'] as int?,
      rating: json['rating'] as int?,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
      progressPercent:
          (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      book: Book(
        id: json['book_id'] as String?,
        isbn: json['isbn'] as String?,
        title: json['title'] as String? ?? 'Sem título',
        authors: (json['authors'] as List<dynamic>?)
                ?.map((a) => a.toString())
                .toList() ??
            [],
        publisher: json['publisher'] as String?,
        coverUrl: json['cover_url'] as String?,
        description: json['description'] as String?,
      ),
    );
  }
}
