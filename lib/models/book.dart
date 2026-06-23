class Book {
  final String? id;
  final String? isbn;
  final String title;
  final List<String> authors;
  final String? publisher;
  final String? publishedDate;
  final int? pageCount;
  final String? coverUrl;
  final String? description;
  final String source;

  Book({
    this.id,
    this.isbn,
    required this.title,
    this.authors = const [],
    this.publisher,
    this.publishedDate,
    this.pageCount,
    this.coverUrl,
    this.description,
    this.source = 'manual',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String?,
      isbn: json['isbn'] as String?,
      title: json['title'] as String? ?? 'Sem título',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((a) => a.toString())
              .toList() ??
          [],
      publisher: json['publisher'] as String?,
      publishedDate: json['published_date'] as String?,
      pageCount: json['page_count'] as int?,
      coverUrl: json['cover_url'] as String?,
      description: json['description'] as String?,
      source: json['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (isbn != null) 'isbn': isbn,
      'title': title,
      'authors': authors,
      'publisher': publisher,
      'published_date': publishedDate,
      'page_count': pageCount,
      'cover_url': coverUrl,
      'description': description,
      'source': source,
    };
  }

  String get authorsLabel =>
      authors.isEmpty ? 'Autor desconhecido' : authors.join(', ');
}
