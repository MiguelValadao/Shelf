import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_book.dart';

class BookCard extends StatelessWidget {
  final UserBook userBook;
  final VoidCallback onTap;

  const BookCard({super.key, required this.userBook, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isReading = userBook.status == ReadingStatus.reading;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: userBook.book.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: userBook.book.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholderCover(),
                        placeholder: (_, __) => _placeholderCover(loading: true),
                      )
                    : _placeholderCover(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userBook.book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            userBook.book.authorsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          if (isReading) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (userBook.progressPercent / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${userBook.progressPercent.toStringAsFixed(0)}% lido',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholderCover({bool loading = false}) {
    return Container(
      color: const Color(0xFFEFE6DA),
      alignment: Alignment.center,
      child: loading
          ? const CircularProgressIndicator(strokeWidth: 2)
          : const Icon(Icons.menu_book, color: Color(0xFF5B4636), size: 32),
    );
  }
}
