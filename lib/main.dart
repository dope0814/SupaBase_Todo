import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/screens/splash_page.dart';
import 'package:todo_app/theme/app_theme.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_APP_KEY']);

  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: AppTheme.notionLikeThmem,
      home: const SplashPage(),
    );
  }
}
