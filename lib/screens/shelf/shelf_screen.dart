import 'package:flutter/material.dart';
import '../../models/user_book.dart';
import '../../services/shelf_repository.dart';
import '../../services/auth_repository.dart';
import '../../widgets/book_card.dart';
import '../add_book/add_book_screen.dart';
import '../book/book_detail_screen.dart';
import '../auth/login_screen.dart';

class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key});

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  final _shelfRepository = ShelfRepository();
  final _authRepository = AuthRepository();

  ReadingStatus? _filter;
  late Future<List<UserBook>> _shelfFuture;

  @override
  void initState() {
    super.initState();
    _loadShelf();
  }

  void _loadShelf() {
    _shelfFuture = _shelfRepository.getShelf(statusFilter: _filter);
  }

  Future<void> _refresh() async {
    setState(_loadShelf);
    await _shelfFuture;
  }

  void _setFilter(ReadingStatus? status) {
    setState(() {
      _filter = status;
      _loadShelf();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Estante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await _authRepository.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<UserBook>>(
                future: _shelfFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  final books = snapshot.data ?? [];
                  if (books.isEmpty) {
                    return ListView(
                      // ListView para o RefreshIndicator funcionar mesmo vazio
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Sua estante está vazia.\nToque em + para adicionar um livro.', textAlign: TextAlign.center)),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: books.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.55,
                    ),
                    itemBuilder: (context, index) {
                      final userBook = books[index];
                      return BookCard(
                        userBook: userBook,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookDetailScreen(userBookId: userBook.userBookId),
                            ),
                          );
                          _refresh();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddBookScreen()),
          );
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = <ReadingStatus?>[null, ...ReadingStatus.values];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = filters[index];
          final isSelected = _filter == status;
          return ChoiceChip(
            label: Text(status == null ? 'Todos' : status.label),
            selected: isSelected,
            onSelected: (_) => _setFilter(status),
          );
        },
      ),
    );
  }
}
