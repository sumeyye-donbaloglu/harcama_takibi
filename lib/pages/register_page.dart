import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
  //bu ekranın durumunu _RegisterPageState yönetecek diyor.
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt ol')),
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
              obscureText: true, //şifreyi ekranda gizlemek için
              autocorrect: false, //yazım düzeltmesi kapalı
              enableSuggestions: false, //öneriler kapalı
              decoration: InputDecoration(
                labelText: "Şifre girin",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorText != null)
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: Text(_isLoading ? 'Kaydediliyor...' : 'Kayıt ol'),
            ),
          ],
        ),
      ),
    );
  }

  //controllerı build dışında oluşturuyoruz çünkü buildin içinde her seferinde oluşsun istemiyoruz
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorText;
  bool _isLoading =
      false; //false ise kayıt isteği sürmüyor,true ise firebasein cevabını bekliyoruz.
  //isloading == hesap oluşturma işi biraz sürebileceği için ekranın kayıt sürüyor bilgisini tutabileceği bir değişkene ihtiyaç duyduk

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Lütfen e-posta ve şifreni gir.';
      });
      return; //eğer mail veya şifreleme hatalıysa firebase e istek atmayacak ve hata mesajı görünüp fonksiyonun geri kalan kısmı çalışmayacak
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(); //kayıt ekranını kapatıyoruz
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return; //Firebasei beklerken kullanıcı ekranı kapatırsa ekranı güncellemeye çalışmayacak ve hata vermeyecek
      }
      setState(() {
        if (error.code == 'email-already-in-use') {
          _errorText = 'Bu e-posta adresi zaten kullanılıyor.';
        } else if (error.code == 'weak-password') {
          _errorText = 'Şifre çok zayıf. Lütfen daha güçlü bir şifre giriniz.';
        } else if (error.code == 'invalid-email') {
          _errorText = 'Geçersiz e-posta adresi.';
        } else {
          _errorText = 'Kayıt oluşturulamadı. Tekrar deneyin.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = "Beklenmeyen bir hata oluştu. tekrar deneyin.";
      });
    } finally {
      //finally her zaman çalışır.
      if (mounted) {
        //ekran açık kalmışsa
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
