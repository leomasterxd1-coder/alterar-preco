import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlterarPrecoApp());
}

class AlterarPrecoApp extends StatelessWidget {
  const AlterarPrecoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alterar Preço',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const LoginScreen(),
    );
  }
}
