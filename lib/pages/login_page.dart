import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorText;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = "Lütfen e-posta ve şifre alanlarını girin.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        if (error.code == "invalid-email") {
          _errorText = "Geçerli bir e-posta adresi giriniz.";
        } else if (error.code == "invalid-credential" ||
            error.code == "wrong-password" ||
            error.code == "user-not-found") {
          _errorText = "E-posta veya şifre hatalı.";
        } else if (error.code == "network-request-failed") {
          _errorText =
              "Bağlantı kurulamadı.Lütfen internet bağlantınızı kontrol edin.";
        } else {
          _errorText = "Giriş yapılamadı.Tekrar deneyiniz.";
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = "Beklenmeyen bir hata oluştu.Tekrar deneyin.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş yap")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: "E-posta",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: "Şifre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorText != null) //koşullu widget kullanımı
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: Text(_isLoading ? "Giriş yapılıyor..." : "Giriş yap"),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      //düğmeye basılınca açılacak fonk
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
              child: const Text('Hesabın yok mu? Kayıt ol'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
