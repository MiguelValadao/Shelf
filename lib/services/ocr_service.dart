import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extrai todo o texto detectado em uma imagem.
  /// O processamento é feito 100% no dispositivo (não envia a imagem
  /// para nenhum servidor), o que é mais rápido e preserva a privacidade.
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Retorna os blocos de texto separadamente, útil se você quiser
  /// deixar o usuário tocar em um bloco específico (ex: um parágrafo)
  /// em vez de pegar a imagem inteira como quote.
  Future<List<TextBlock>> extractBlocks(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
    return recognizedText.blocks;
  }

  void dispose() {
    _recognizer.close();
  }
}
