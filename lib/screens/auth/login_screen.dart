
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kalp_atisi_app/screens/auth/register_screen.dart';
import 'package:kalp_atisi_app/screens/main_screen.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';
import 'package:kalp_atisi_app/data/data_service.dart';

class LoginScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;
  final AlarmService alarmService;
  final DataService dataService;

  const LoginScreen({
    super.key,
    required this.bluetoothService,
    required this.alarmService,
    required this.dataService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigate to home screen or main screen with existing services
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(
            bluetoothService: widget.bluetoothService,
            alarmService: widget.alarmService,
            dataService: widget.dataService,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giriş Yap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Section
            Image.asset(
              'logo.png',
              height: 120,
              width: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'Kalp Atışı İzleyici',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Şifre'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Giriş Yap'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to registration screen
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
              child: const Text('Hesabın yok mu? Kayıt ol'),
            ),
          ],
        ),
      ),
    );
  }
}
