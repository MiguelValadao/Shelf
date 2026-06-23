import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/quote.dart';
import '../../models/user_book.dart';
import '../../services/shelf_repository.dart';
import 'add_quote_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final String userBookId;

  const BookDetailScreen({super.key, required this.userBookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _shelfRepository = ShelfRepository();

  late Future<UserBook> _userBookFuture;
  late Future<List<Quote>> _quotesFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _userBookFuture = _shelfRepository.getUserBookById(widget.userBookId);
    _quotesFuture = _shelfRepository.getQuotes(widget.userBookId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_userBookFuture, _quotesFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do livro')),
      body: FutureBuilder<UserBook>(
        future: _userBookFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final userBook = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(userBook),
                const SizedBox(height: 20),
                _buildStatusSelector(userBook),
                const SizedBox(height: 20),
                if (userBook.status == ReadingStatus.reading)
                  _buildProgressSection(userBook),
                const SizedBox(height: 24),
                _buildQuotesSection(userBook),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserBook userBook) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 90,
            height: 130,
            child: userBook.book.coverUrl != null
                ? CachedNetworkImage(imageUrl: userBook.book.coverUrl!, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFFEFE6DA),
                    child: const Icon(Icons.menu_book, color: Color(0xFF5B4636)),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userBook.book.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(userBook.book.authorsLabel, style: TextStyle(color: Colors.grey[600])),
              if (userBook.book.publisher != null) ...[
                const SizedBox(height: 4),
                Text(userBook.book.publisher!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector(UserBook userBook) {
    return Wrap(
      spacing: 8,
      children: ReadingStatus.values.map((status) {
        final isSelected = userBook.status == status;
        return ChoiceChip(
          label: Text(status.label),
          selected: isSelected,
          onSelected: (_) async {
            await _shelfRepository.updateStatus(userBook.userBookId, status);
            _refresh();
          },
        );
      }).toList(),
    );
  }

  Widget _buildProgressSection(UserBook userBook) {
    final totalPages = userBook.totalPages ?? userBook.book.pageCount ?? 0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progresso de leitura', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${userBook.progressPercent.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (userBook.progressPercent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Página ${userBook.currentPage} de $totalPages'),
                const Spacer(),
                TextButton(
                  onPressed: () => _showUpdatePageDialog(userBook, totalPages),
                  child: const Text('Atualizar página'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdatePageDialog(UserBook userBook, int totalPages) async {
    final controller = TextEditingController(text: userBook.currentPage.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atualizar página atual'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(labelText: 'Página (de $totalPages)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _shelfRepository.updateProgress(
        userBookId: userBook.userBookId,
        currentPage: result.clamp(0, totalPages == 0 ? result : totalPages),
        totalPages: userBook.totalPages == null && userBook.book.pageCount != null
            ? userBook.book.pageCount
            : null,
      );
      _refresh();
    }
  }

  Widget _buildQuotesSection(UserBook userBook) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Quotes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Adicionar'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddQuoteScreen(userBookId: userBook.userBookId),
                  ),
                );
                _refresh();
              },
            ),
          ],
        ),
        FutureBuilder<List<Quote>>(
          future: _quotesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final quotes = snapshot.data ?? [];
            if (quotes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Nenhuma quote salva ainda.', style: TextStyle(color: Colors.grey[600])),
              );
            }
            return Column(
              children: quotes.map((quote) => _QuoteCard(quote: quote)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;

  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFFBF5),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEFE6DA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${quote.content}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            if (quote.pageNumber != null) ...[
              const SizedBox(height: 6),
              Text('Página ${quote.pageNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }
}
