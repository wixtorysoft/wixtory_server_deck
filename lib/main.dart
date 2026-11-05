import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/server_list_screen.dart';
import 'services/ssh_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SshService()),
      ],
      child: const ServerDeckApp(),
    ),
  );
}

class ServerDeckApp extends StatelessWidget {
  const ServerDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServerDeck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ServerListScreen(),
    );
  }
}
