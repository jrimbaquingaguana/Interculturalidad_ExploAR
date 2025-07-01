import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'itinerary_page.dart';
import 'gallery_page.dart';
import 'AdminPage.dart';  // Importa la página de administración

class MenuPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const MenuPage({super.key, required this.user});

  void _showComingSoon(BuildContext context, String feature) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ${loc.comingSoon}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final items = [
      {
        'label': loc.viewMap,
        'image': 'assets/images/map.png',
        'action': () => _showComingSoon(context, loc.viewMap),
      },
      {
        'label': loc.itinerary,
        'image': 'assets/images/itinerary.png',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ItineraryPage()),
          );
        },
      },
      {
        'label': loc.gallery,
        'image': 'assets/images/gallery.png',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GalleryPage()),
          );
        },
      },
    ];

    if (user['rol'] == 'administrador') {
      items.add({
        'label': loc.administer, // Usar traducción
        'image': 'assets/images/users.png',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminPage()),
          );
        },
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5E9F7),
      appBar: AppBar(
        title: Text(
          loc.mainMenu,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo.shade800,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildMenuCard(
              context: context,
              label: item['label'] as String,
              imagePath: item['image'] as String,
              onTap: item['action'] as VoidCallback,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String label,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Focus(
      child: GestureDetector(
        onTap: onTap,
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasFocus ? Colors.indigo : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        imagePath,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
