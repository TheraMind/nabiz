import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Kalp Atışı İzleyici uygulaması, sağlık verilerinizi cihazınızda ve Firebase üzerinde saklar. '
          'Toplanan veriler üçüncü şahıslarla paylaşılmaz. Uygulamayı kullanarak verilerinizin '
          'işlenmesini ve saklanmasını kabul etmiş olursunuz.',
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
