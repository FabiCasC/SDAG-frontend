import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDAG - Tutorial de Bienvenida',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TutorialPage(),
    );
  }
}

class TutorialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        // Página 1: Introducción general
        PageViewModel(
          title: "Bienvenido a SDAG",
          body: "Una breve descripción de cómo utilizar la app.",
          image: Image.asset('assets/tutorial1.png', width: 350),
          decoration: PageDecoration(
            pageColor: Colors.blue[50]!,
            titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontSize: 16),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
        // Página 2: Características de la app
        PageViewModel(
          title: "Características",
          body: "Explora las funciones principales de la app.",
          image: Image.asset('assets/tutorial2.png', width: 350),
          decoration: PageDecoration(
            pageColor: Colors.blue[50]!,
            titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontSize: 16),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
        // Página 3: Cómo empezar
        PageViewModel(
          title: "¿Cómo empezar?",
          body: "Aquí te mostramos cómo iniciar.",
          image: Image.asset('assets/tutorial3.png', width: 350),
          decoration: PageDecoration(
            pageColor: Colors.blue[50]!,
            titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            bodyTextStyle: TextStyle(fontSize: 16),
            imagePadding: EdgeInsets.all(24),
          ),
        ),
      ],
      onDone: () {
        // Acción cuando el tutorial se ha completado
        print("Tutorial completado");
        // Redirigir al usuario a la pantalla principal o alguna otra vista
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      },
      onSkip: () {
        // Acción cuando el usuario omite el tutorial
        print("Tutorial omitido");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      },
      showSkipButton: true,
      skip: Text("Saltar"),
      next: Icon(Icons.arrow_forward),
      done: Text("Comenzar", style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pantalla Principal')),
      body: Center(child: Text('¡Bienvenido a la aplicación!')),
    );
  }
}