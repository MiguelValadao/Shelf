import 'package:flutter/material.dart';
import 'manual_form_screen.dart';
import 'scan_barcode_screen.dart';
import 'isbn_search_screen.dart';

class AddBookScreen extends StatelessWidget {
  const AddBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar livro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _OptionCard(
              icon: Icons.qr_code_scanner,
              title: 'Escanear código de barras',
              subtitle: 'Use a câmera para ler o ISBN da contracapa',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanBarcodeScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.search,
              title: 'Buscar por ISBN',
              subtitle: 'Digite o ISBN se já souber o número',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IsbnSearchScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.edit_note,
              title: 'Cadastro manual',
              subtitle: 'Preencha os dados do livro à mão',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManualFormScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFEFE6DA),
          child: Icon(icon, color: const Color(0xFF5B4636)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
