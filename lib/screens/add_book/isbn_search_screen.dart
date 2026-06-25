import 'package:flutter/material.dart';
import '../../services/isbn_lookup_service.dart';
import 'manual_form_screen.dart';

class IsbnSearchScreen extends StatefulWidget {
  const IsbnSearchScreen({super.key});

  @override
  State<IsbnSearchScreen> createState() => _IsbnSearchScreenState();
}

class _IsbnSearchScreenState extends State<IsbnSearchScreen> {
  final _isbnController = TextEditingController();
  final _isbnLookupService = IsbnLookupService();
  bool _isLoading = false;

  Future<void> _search() async {
    final isbn = _isbnController.text.trim();
    if (isbn.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final book = await _isbnLookupService.lookup(isbn);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ManualFormScreen(prefill: book)),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorModal(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorModal(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar por ISBN')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _isbnController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Digite o ISBN',
                hintText: 'Ex: 9788535914849',
                prefixIcon: Icon(Icons.numbers),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _search,
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Buscar'),
            ),
          ],
        ),
      ),
    );
  }
}
