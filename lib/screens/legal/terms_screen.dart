import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Koşulları'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          'Bu uygulama tıbbi bir cihaz değildir ve yalnızca bilgilendirme amaçlıdır. '
          'Uygulamayı kullanarak toplanan kalp atış hızı ve SpO₂ verilerinin güvenli bir şekilde '
          'saklanmasını kabul etmiş olursunuz. Elde edilen veriler tanı veya tedavi amacıyla '
          'kullanılmamalıdır. Cihazınızın Bluetooth özelliğini etkinleştirmeniz ve '
          'uygulamaya gerekli izinleri vermeniz gerekmektedir.',
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
