import 'package:flutter/material.dart';
import 'package:pixels/pixels.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixels Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controller = PixelImageController(
      customGradientEquation: (y) =>
          Color.fromARGB(255, 0, 0, (255 * y).toInt()),
      width: 64,
      height: 64,
      brushColor: Colors.red.withAlpha(100),
      brushSize: 10,
      bgColor: Colors.grey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: PixelEditor(
          controller: _controller,
        ),
      ),
    );
  }
}
