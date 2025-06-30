import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final TextEditingController _ciudadController = TextEditingController();
  Color _selectedColor = Colors.blue;

  // Lista de ciudades para mantener índice fijo y estado expandido
  final List<String> _ciudadesKeys = [];
  final Map<String, Map<String, dynamic>> _ciudades = {};

  @override
  void initState() {
    super.initState();
    _cargarCiudades();
  }

  Future<String> _getLocalPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<File> get _localFile async {
    final path = await _getLocalPath();
    return File('$path/ciudades.json');
  }

  Future<void> _guardarCiudades() async {
    final file = await _localFile;

    final Map<String, dynamic> jsonMap = _ciudades.map((key, value) {
      return MapEntry(
        key,
        {
          'color': value['color'].value,
          'photos': value['photos'],
          'expanded': value['expanded'],
        },
      );
    });

    final jsonString = json.encode(jsonMap);
    await file.writeAsString(jsonString);
  }

  Future<void> _cargarCiudades() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return;

      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final Map<String, Map<String, dynamic>> loadedCiudades = {};

      jsonMap.forEach((key, value) {
        loadedCiudades[key] = {
          'color': Color(value['color']),
          'photos': List<String>.from(value['photos']),
          'expanded': value['expanded'] ?? false,
        };
      });

      setState(() {
        _ciudades.clear();
        _ciudades.addAll(loadedCiudades);
        _ciudadesKeys.clear();
        _ciudadesKeys.addAll(_ciudades.keys);
      });
    } catch (e) {
      debugPrint('Error cargando ciudades: $e');
    }
  }

  Future<void> _mostrarDialogoCiudad({String? ciudadOriginal}) async {
    _ciudadController.text = ciudadOriginal ?? '';
    _selectedColor =
        ciudadOriginal != null ? _ciudades[ciudadOriginal]!['color'] : Colors.blue;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(ciudadOriginal == null
                ? AppLocalizations.of(context)?.addCity ?? 'Add City'
                : AppLocalizations.of(context)?.editDestination ?? 'Edit City'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _ciudadController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.writeHere ?? 'Write here...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(AppLocalizations.of(context)?.selectColor ?? "Select Color:"),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final color = await showDialog<Color>(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: Text(AppLocalizations.of(context)?.selectColor ??
                                "Select Color"),
                            children: [
                              _colorOption(Colors.blue, setStateDialog),
                              _colorOption(Colors.red, setStateDialog),
                              _colorOption(Colors.green, setStateDialog),
                              _colorOption(Colors.orange, setStateDialog),
                              _colorOption(Colors.purple, setStateDialog),
                              _colorOption(Colors.teal, setStateDialog),
                            ],
                          ),
                        );
                        if (color != null) {
                          setStateDialog(() => _selectedColor = color);
                        }
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black54),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final nombre = _ciudadController.text.trim();
                  if (nombre.isEmpty) return;

                  setState(() {
                    if (ciudadOriginal == null) {
                      if (!_ciudades.containsKey(nombre)) {
                        _ciudades[nombre] = {
                          'color': _selectedColor,
                          'photos': <String>[],
                          'expanded': true,
                        };
                        _ciudadesKeys.add(nombre);
                      }
                    } else {
                      if (nombre != ciudadOriginal) {
                        if (_ciudades.containsKey(nombre)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('City name already exists')),
                          );
                          return;
                        }
                        final data = _ciudades[ciudadOriginal]!;
                        _ciudades.remove(ciudadOriginal);
                        _ciudades[nombre] = data;

                        final index = _ciudadesKeys.indexOf(ciudadOriginal);
                        if (index != -1) {
                          _ciudadesKeys[index] = nombre;
                        }
                      }
                      _ciudades[nombre]!['color'] = _selectedColor;
                    }
                  });

                  await _guardarCiudades();
                  Navigator.pop(context);
                },
                child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _colorOption(Color color, void Function(void Function()) setStateDialog) {
    return SimpleDialogOption(
      onPressed: () {
        setStateDialog(() {
          _selectedColor = color;
        });
        Navigator.pop(context, color);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black54),
        ),
      ),
    );
  }

  Future<void> _subirFoto(String ciudad) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final File imageFile = File(pickedFile.path);
    final appDirPath = await _getLocalPath();

    final cityDir = Directory('$appDirPath/$ciudad');
    if (!await cityDir.exists()) {
      await cityDir.create(recursive: true);
    }

    final String newPath =
        '${cityDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File newImage = await imageFile.copy(newPath);

    setState(() {
      _ciudades[ciudad]!['photos'].add(newImage.path);
    });

    await _guardarCiudades();
  }

  Future<void> _eliminarCiudad(String ciudad) async {
  final loc = AppLocalizations.of(context);
  final mensajeConfirmacion = loc?.confirmDeleteCity(ciudad) ?? 'Do you want to delete "$ciudad" and all its photos?';

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(loc?.confirmDeleteDestination ?? 'Delete City?'),
      content: Text(mensajeConfirmacion),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(loc?.cancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(loc?.delete ?? 'Delete'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final appDirPath = await _getLocalPath();
    final cityDir = Directory('$appDirPath/$ciudad');
    if (await cityDir.exists()) {
      await cityDir.delete(recursive: true);
    }

    setState(() {
      _ciudades.remove(ciudad);
      _ciudadesKeys.remove(ciudad);
    });

    await _guardarCiudades();
  }
}


  Future<void> _eliminarFoto(String ciudad, int index) async {
    final path = _ciudades[ciudad]!['photos'][index] as String;

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      _ciudades[ciudad]!['photos'].removeAt(index);
    });

    await _guardarCiudades();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(
          loc.gallery,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoCiudad(),
        child: const Icon(Icons.add),
        tooltip: loc.addCity,
      ),
      body: _ciudades.isEmpty
          ? Center(child: Text(loc.noDestinationsAdded))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: List.generate(_ciudadesKeys.length, (index) {
                final ciudad = _ciudadesKeys[index];
                final data = _ciudades[ciudad]!;
                final color = data['color'] as Color;
                final photos = data['photos'] as List<String>;
                final expanded = data['expanded'] as bool;

                return Card(
                  color: color.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionPanelList(
                    elevation: 0,
                    expandedHeaderPadding: EdgeInsets.zero,
                    expansionCallback: (panelIndex, isExpanded) {
                      setState(() {
                        data['expanded'] = !isExpanded;
                      });
                      _guardarCiudades();
                    },
                    children: [
                      ExpansionPanel(
                        canTapOnHeader: true,
                        isExpanded: expanded,
                        headerBuilder: (context, isExpanded) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Círculo con color real
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black26),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Texto con color oscuro
                                    Text(
                                      ciudad,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: color.darken(0.3),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: color.darken(0.3),
                                      tooltip: loc.editDestination,
                                      onPressed: () => _mostrarDialogoCiudad(ciudadOriginal: ciudad),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: color.darken(0.3),
                                      tooltip: loc.deleteDestination,
                                      onPressed: () => _eliminarCiudad(ciudad),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_a_photo),
                                      onPressed: () => _subirFoto(ciudad),
                                      tooltip: loc.addPhoto,
                                      color: color.darken(0.3),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        body: photos.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(loc.noPhotosYet),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: color.darken(0.3)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 4 / 3,
                                    ),
                                    itemCount: photos.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => Dialog(
                                                    backgroundColor: Colors.black87,
                                                    child: GestureDetector(
                                                      onTap: () =>
                                                          Navigator.of(context).pop(),
                                                      child: InteractiveViewer(
                                                        child: Image.file(
                                                          File(photos[index]),
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: AspectRatio(
                                                aspectRatio: 4 / 3,
                                                child: Image.file(
                                                  File(photos[index]),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: GestureDetector(
                                              onTap: () => _eliminarFoto(ciudad, index),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 22,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}

extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
