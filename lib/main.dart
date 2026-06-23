import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_repository.dart';
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shelf/shelf_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseService.initialize();
  runApp(const BookMoryApp());
}

class BookMoryApp extends StatelessWidget {
  const BookMoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookMory Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// Decide se mostra a tela de login ou a estante, com base no
/// estado de autenticação do Supabase, e reage a mudanças (login/logout).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return StreamBuilder(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = authRepository.isLoggedIn;
        return isLoggedIn ? const ShelfScreen() : const LoginScreen();
      },
    );
  }
}
