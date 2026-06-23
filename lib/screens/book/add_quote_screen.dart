import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/quote.dart';
import '../../services/ocr_service.dart';
import '../../services/shelf_repository.dart';

class AddQuoteScreen extends StatefulWidget {
  final String userBookId;

  const AddQuoteScreen({super.key, required this.userBookId});

  @override
  State<AddQuoteScreen> createState() => _AddQuoteScreenState();
}

class _AddQuoteScreenState extends State<AddQuoteScreen> {
  final _ocrService = OcrService();
  final _shelfRepository = ShelfRepository();
  final _imagePicker = ImagePicker();
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();

  File? _capturedImage;
  bool _isProcessingOcr = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _ocrService.dispose();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Abre a câmera, tira a foto da página/trecho do livro e roda o OCR
  /// on-device (ML Kit) para extrair o texto automaticamente.
  Future<void> _captureAndExtract() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (pickedFile == null) return;

    setState(() {
      _capturedImage = File(pickedFile.path);
      _isProcessingOcr = true;
    });

    try {
      final extractedText = await _ocrService.extractText(pickedFile.path);
      setState(() => _contentController.text = extractedText.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar OCR: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingOcr = false);
    }
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite ou capture o texto da quote.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _shelfRepository.addQuote(
        Quote(
          userBookId: widget.userBookId,
          content: content,
          pageNumber: int.tryParse(_pageController.text.trim()),
          source: _capturedImage != null ? 'ocr' : 'manual',
        ),
      );
      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova quote')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_capturedImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_capturedImage!, height: 180, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_capturedImage == null
                ? 'Fotografar trecho do livro'
                : 'Tirar outra foto'),
            onPressed: _isProcessingOcr ? null : _captureAndExtract,
          ),
          const SizedBox(height: 16),
          if (_isProcessingOcr)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Reconhecendo texto...'),
                ],
              ),
            ),
          Text(
            'Texto extraído (revise antes de salvar):',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _contentController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'O texto da quote aparece aqui, ou digite manualmente...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Número da página (opcional)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Salvar quote'),
          ),
        ],
      ),
    );
  }
}
