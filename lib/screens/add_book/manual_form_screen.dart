import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/user_book.dart';
import '../../services/shelf_repository.dart';

/// Tela compartilhada: usada tanto para o cadastro 100% manual quanto
/// para confirmar/editar os dados que vieram do scanner/busca por ISBN
/// e para editar dados de um livro já existente.
class ManualFormScreen extends StatefulWidget {
  final Book? prefill;
  final String? editingBookId;

  const ManualFormScreen({super.key, this.prefill, this.editingBookId});

  bool get isEditing => editingBookId != null;

  @override
  State<ManualFormScreen> createState() => _ManualFormScreenState();
}

class _ManualFormScreenState extends State<ManualFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shelfRepository = ShelfRepository();

  late final _titleController = TextEditingController(text: widget.prefill?.title);
  late final _authorsController =
      TextEditingController(text: widget.prefill?.authors.join(', '));
  late final _isbnController = TextEditingController(text: widget.prefill?.isbn);
  late final _publisherController = TextEditingController(text: widget.prefill?.publisher);
  late final _pageCountController =
      TextEditingController(text: widget.prefill?.pageCount?.toString());
  late final _coverUrlController = TextEditingController(text: widget.prefill?.coverUrl);

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _pageCountController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar livro' : 'Cadastro manual'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.prefill != null && !widget.isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Dados encontrados automaticamente. Revise antes de salvar.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _authorsController,
              decoration: const InputDecoration(
                labelText: 'Autor(es)',
                hintText: 'Separe por vírgula se houver mais de um',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(labelText: 'ISBN'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _publisherController,
              decoration: const InputDecoration(labelText: 'Editora'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pageCountController,
              decoration: const InputDecoration(labelText: 'Número de páginas'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coverUrlController,
              decoration: const InputDecoration(labelText: 'URL da capa'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isEditing ? 'Salvar alterações' : 'Salvar na estante'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final book = Book(
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        title: _titleController.text.trim(),
        authors: _authorsController.text
            .split(',')
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList(),
        publisher: _publisherController.text.trim().isEmpty ? null : _publisherController.text.trim(),
        pageCount: int.tryParse(_pageCountController.text.trim()),
        coverUrl: _coverUrlController.text.trim().isEmpty ? null : _coverUrlController.text.trim(),
        source: widget.prefill?.source ?? 'manual',
      );

      if (widget.isEditing) {
        await _shelfRepository.updateBook(widget.editingBookId!, book);
      } else {
        await _shelfRepository.addBookToShelf(book: book, status: ReadingStatus.toRead);
      }

      if (mounted) {
        if (widget.isEditing) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
