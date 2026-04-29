import 'package:flutter/material.dart';

class SelectorIdiomas extends StatefulWidget {
  const SelectorIdiomas({super.key});

  @override
  State<SelectorIdiomas> createState() => _SelectorIdiomasState();
}

class _SelectorIdiomasState extends State<SelectorIdiomas> {
  bool isEnglish = false;

  // Definición de la paleta oficial de Figma
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color energeticOrange = Color(0xFFF97316);
  static const Color textPrimary = Color(0xFF314158);
  static const Color white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: Text(isEnglish ? 'Language Selection' : 'Selector de Idiomas'),
        backgroundColor: primaryBlue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 100, color: primaryBlue),
            const SizedBox(height: 30),
            Text(
              isEnglish ? 'Choose your language' : 'Elige tu idioma',
              style: const TextStyle(
                color: textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            // Botón de Idioma
            _buildLanguageButton(
              label: 'ESPAÑOL', 
              isActive: !isEnglish, 
              onTap: () => setState(() => isEnglish = false)
            ),
            const SizedBox(height: 20),
            _buildLanguageButton(
              label: 'ENGLISH', 
              isActive: isEnglish, 
              onTap: () => setState(() => isEnglish = true)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton({required String label, required bool isActive, required VoidCallback onTap}) {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? energeticOrange : Colors.grey[200],
          foregroundColor: isActive ? white : textPrimary,
          elevation: isActive ? 4 : 0,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}