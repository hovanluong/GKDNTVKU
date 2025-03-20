import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vls_shoes/screens/login_screen.dart';
import 'package:vls_shoes/services/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDBService.connect();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VLS Shoes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}