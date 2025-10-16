import 'package:flutter_test/flutter_test.dart';
import 'package:kalp_atisi_app/bluetooth/app_bluetooth_service.dart';
import 'package:kalp_atisi_app/data/data_service.dart';
import 'package:kalp_atisi_app/main.dart';
import 'package:kalp_atisi_app/services/alarm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kalp_atisi_app/firebase_options.dart';

// Servisler için sahte (mock) sınıflar
class MockBluetoothService extends AppBluetoothService {}
class MockDataService extends DataService {}

void main() {
  testWidgets('Main app builds and shows welcome screen', (WidgetTester tester) async {
    // Sahte servisleri oluştur
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final mockBluetoothService = AppBluetoothService();
    final mockAlarmService = AlarmService(
      mockBluetoothService,
      FlutterLocalNotificationsPlugin(),
    );
    final mockDataService = DataService();

    // Uygulamayı sahte servislerle başlat
    await tester.pumpWidget(MyApp(
      bluetoothService: mockBluetoothService,
      alarmService: mockAlarmService,
      dataService: mockDataService,
    ));

    // WelcomeScreen'in göründüğünü doğrula
    // Bu test, uygulamanın ana yapısının doğru kurulduğunu ve
    // başlangıç ekranının yüklendiğini basitçe kontrol eder.
    expect(find.text('Kalp Atışı ve SpO2 Takip Uygulaması'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);
  });
}