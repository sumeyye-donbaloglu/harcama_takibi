import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:provider/provider.dart';
import '../provider/transaction_provider.dart';
import '../services/transaction_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          return ChangeNotifierProvider(
            key: ValueKey(user.uid),
            create: (context) {
              final service = TransactionService(userId: user.uid);

              return TransactionProvider(service: service);
            },
            child: const MyHomePage(title: 'Harcama Takibi'),
          );
        }
        return const LoginPage();
      },
    );
  }
}
