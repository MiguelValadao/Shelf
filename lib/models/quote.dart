class Quote {
  final String? id;
  final String userBookId;
  final String content;
  final int? pageNumber;
  final String? note;
  final String source; // 'ocr' | 'manual'
  final DateTime? createdAt;

  Quote({
    this.id,
    required this.userBookId,
    required this.content,
    this.pageNumber,
    this.note,
    this.source = 'manual',
    this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String?,
      userBookId: json['user_book_id'] as String,
      content: json['content'] as String,
      pageNumber: json['page_number'] as int?,
      note: json['note'] as String?,
      source: json['source'] as String? ?? 'manual',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_book_id': userBookId,
      'content': content,
      'page_number': pageNumber,
      'note': note,
      'source': source,
    };
  }
}
