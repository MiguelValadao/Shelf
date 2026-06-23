import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../../models/user_book.dart';
import '../../services/shelf_repository.dart';

/// Tela compartilhada: usada tanto para o cadastro 100% manual quanto
/// para confirmar/editar os dados que vieram do scanner/busca por ISBN.
class ManualFormScreen extends StatefulWidget {
  final Book? prefill;

  const ManualFormScreen({super.key, this.prefill});

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

  ReadingStatus _status = ReadingStatus.toRead;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final isConfirmation = widget.prefill != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isConfirmation ? 'Confirme os dados' : 'Cadastro manual'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (isConfirmation)
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
              decoration: const InputDecoration(labelText: 'URL da capa (opcional)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReadingStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ReadingStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? ReadingStatus.toRead),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Salvar na estante'),
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

      await _shelfRepository.addBookToShelf(book: book, status: _status);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
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
