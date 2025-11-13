import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maicosoft/app_route.dart';
import 'package:maicosoft/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MaicoSoft - Dashboard',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFD00236),
          onPrimary: Colors.white,
          secondary: Color(0xFF590017),
          onSecondary: Colors.white,
          error: Colors.black,
          onError: Colors.white,
          surface: Color(0xFFEEEEEE),
          onSurface: Color(0xFF171717),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
