import 'package:flutter/material.dart';
import 'package:kalp_atisi_app/main.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';
import 'package:kalp_atisi_app/data/data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalp_atisi_app/screens/legal/terms_screen.dart';
import 'package:kalp_atisi_app/screens/legal/privacy_policy_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final AppBluetoothService bluetoothService;
  final AlarmService alarmService;
  final DataService dataService;

  const WelcomeScreen({super.key, required this.bluetoothService, required this.alarmService, required this.dataService});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              const OnboardingPage(
                icon: Icons.monitor_heart,
                title: 'Kalp Atışı İzleyici',
                description: 'Bluetooth üzerinden kalp atış hızı ve SpO₂ ölçümlerinizi takip ederek sağlığınızı yakından izleyin.',
              ),
              const OnboardingPage(
                icon: Icons.alarm,
                title: 'Anlık Alarmlar',
                description: 'Belirlediğiniz eşiklerin dışında değer algılandığında bildirim alarak hızlıca önlem alın.',
              ),
              const OnboardingPage(
                icon: Icons.history,
                title: 'Geçmiş Veriler',
                description: 'Eski ölçümlerinize grafikler üzerinden erişebilir ve gelişiminizi takip edebilirsiniz.',
              ),
              OnboardingPage(
                icon: Icons.verified_user,
                title: 'Sözleşme',
                description: 'Uygulamayı kullanabilmek için kullanım koşullarını ve gizlilik politikasını kabul etmelisiniz.',
                extra: Column(
                  children: [
                    CheckboxListTile(
                      value: _termsAccepted,
                      onChanged: (val) {
                        setState(() {
                          _termsAccepted = val ?? false;
                        });
                      },
                      title: const Text('Sözleşmeyi kabul ediyorum'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (c) => const TermsScreen(),
                              ),
                            );
                          },
                          child: const Text('Kullanım Koşulları'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (c) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                          child: const Text('Gizlilik Politikası'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20.0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) => buildDot(index, context)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_currentPage == 3) {
                      if (!_termsAccepted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Devam etmek için sözleşmeyi kabul etmelisiniz.')),
                        );
                        return;
                      }
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('seen', true);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => MainScreen(
                            bluetoothService: widget.bluetoothService,
                            alarmService: widget.alarmService,
                            dataService: widget.dataService,
                          ),
                        ),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Text(_currentPage == 3 ? 'Başlayın' : 'İleri'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentPage == index ? 25 : 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? extra;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 20),
            extra!,
          ],
        ],
      ),
    );
  }
}