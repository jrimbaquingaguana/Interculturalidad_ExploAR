import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature aún no está implementado'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menú Principal',
          style: TextStyle(
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 3,
                color: Colors.black45,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.indigo.shade900,
        centerTitle: true,
        elevation: 6,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0E7FF), Color(0xFF8B9DC3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton(
              context,
              icon: Icons.map_outlined,
              label: 'Ver Mapa',
              onPressed: () => _showComingSoon(context, 'Ver Mapa'),
              color: Colors.indigo.shade800,
              textColor: Colors.white,
            ),
            const SizedBox(height: 24),
            _buildMenuButton(
              context,
              icon: Icons.schedule_outlined,
              label: 'Itinerario',
              onPressed: () => _showComingSoon(context, 'Itinerario'),
              color: Colors.indigo.shade800,
              textColor: Colors.white,
            ),
            const SizedBox(height: 24),
            _buildMenuButton(
              context,
              icon: Icons.photo_library_outlined,
              label: 'Galería',
              onPressed: () => _showComingSoon(context, 'Galería'),
              color: Colors.indigo.shade800,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed,
      Color? color,
      Color? textColor}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).primaryColor,
          elevation: 8,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.white,
          ),
        ),
        icon: Icon(icon, size: 28, color: textColor ?? Colors.white),
        label: Text(
          label,
          style: TextStyle(color: textColor ?? Colors.white),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
