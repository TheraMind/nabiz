
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kalp_atisi_app/main.dart'; // MainScreen için
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kalp_atisi_app/data/data_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigate to home screen or main screen
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen(bluetoothService: AppBluetoothService(), alarmService: AlarmService(AppBluetoothService(), FlutterLocalNotificationsPlugin()), dataService: DataService(),)));
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
        title: const Text('Kayıt Ol'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo 
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
              onPressed: _register,
              child: const Text('Kayıt Ol'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to login screen
                Navigator.of(context).pop(); // Go back to login screen
              },
              child: const Text('Zaten hesabın var mı? Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
