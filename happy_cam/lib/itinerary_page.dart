import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // para internacionalización
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Clases modelo con serialización a Map para Firestore

class Actividad {
  String descripcion;
  Actividad(this.descripcion);

  Map<String, dynamic> toMap() => {'descripcion': descripcion};
  factory Actividad.fromMap(Map<String, dynamic> map) => Actividad(map['descripcion'] ?? '');
}

class Dia {
  int numero;
  List<Actividad> actividades;
  Dia({required this.numero, this.actividades = const []});

  Map<String, dynamic> toMap() => {
        'numero': numero,
        'actividades': actividades.map((a) => a.toMap()).toList(),
      };

  factory Dia.fromMap(Map<String, dynamic> map) => Dia(
        numero: map['numero'] ?? 0,
        actividades: map['actividades'] != null
            ? List<Actividad>.from((map['actividades'] as List).map((a) => Actividad.fromMap(a)))
            : [],
      );
}

class Destino {
  String ciudad;
  List<Dia> dias;
  Color color;
  Destino({required this.ciudad, this.dias = const [], required this.color});

  Map<String, dynamic> toMap() => {
        'ciudad': ciudad,
        'color': color.value,
        'dias': dias.map((d) => d.toMap()).toList(),
      };

  factory Destino.fromMap(Map<String, dynamic> map) => Destino(
        ciudad: map['ciudad'] ?? '',
        color: Color(map['color'] ?? 0xFF000000),
        dias: map['dias'] != null
            ? List<Dia>.from((map['dias'] as List).map((d) => Dia.fromMap(d)))
            : [],
      );
}

class ItineraryPage extends StatefulWidget {
  const ItineraryPage({super.key});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final List<Destino> _destinos = [];
  final List<Color> _coloresDisponibles = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.amberAccent,
    Colors.pinkAccent,
  ];

  final Set<int> _destinosExpandido = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _cargarDestinos();
  }

  // --- Cargar datos desde Firestore ---
  Future<void> _cargarDestinos() async {
    final snapshot = await _firestore.collection('destinos').get();
    final destinosFirestore = snapshot.docs.map((doc) {
      final data = doc.data();
      return Destino.fromMap(data);
    }).toList();

    setState(() {
      _destinos.clear();
      _destinos.addAll(destinosFirestore);
    });
  }

  // --- Guardar todos los destinos a Firestore (sobrescribe colección) ---
  Future<void> _guardarDestinos() async {
    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('destinos');

    // Borra documentos previos
    final existingDocs = await collectionRef.get();
    for (final doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    for (final destino in _destinos) {
      final docRef = collectionRef.doc(destino.ciudad); // Ciudad como id único
      batch.set(docRef, destino.toMap());
    }

    await batch.commit();
  }

  // --- CRUD local + guardado remoto ---

  void _agregarDestino() async {
    final destinoNuevo = await _mostrarDialogoDestino();
    if (destinoNuevo != null) {
      setState(() {
        _destinos.add(destinoNuevo);
      });
      await _guardarDestinos();
    }
  }

  void _editarDestino(int index) async {
    final destinoActual = _destinos[index];
    final destinoEditado = await _mostrarDialogoDestino(destino: destinoActual);
    if (destinoEditado != null) {
      setState(() {
        _destinos[index] = destinoEditado;
      });
      await _guardarDestinos();
    }
  }

  void _eliminarDestino(int index) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.deleteDestination ?? 'Delete destination'),
        content: Text(AppLocalizations.of(context)?.confirmDeleteDestination ??
            'Do you want to delete this destination and all its days and activities?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _destinos.removeAt(index);
                _destinosExpandido.remove(index);
              });
              await _guardarDestinos();
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  void _agregarDia(int destinoIndex) async {
    int nuevoNumero = 1;
    if (_destinos[destinoIndex].dias.isNotEmpty) {
      nuevoNumero = _destinos[destinoIndex].dias.map((d) => d.numero).reduce((a, b) => a > b ? a : b) + 1;
    }
    final nuevoDia = await _mostrarDialogoDia(numeroSugerido: nuevoNumero);
    if (nuevoDia != null) {
      setState(() {
        _destinos[destinoIndex].dias.add(nuevoDia);
        _destinos[destinoIndex].dias.sort((a, b) => a.numero.compareTo(b.numero));
      });
      await _guardarDestinos();
    }
  }

  void _editarDia(int destinoIndex, int diaIndex) async {
    final diaActual = _destinos[destinoIndex].dias[diaIndex];
    final diaEditado = await _mostrarDialogoDia(dia: diaActual);
    if (diaEditado != null) {
      setState(() {
        _destinos[destinoIndex].dias[diaIndex] = diaEditado;
        _destinos[destinoIndex].dias.sort((a, b) => a.numero.compareTo(b.numero));
      });
      await _guardarDestinos();
    }
  }

  void _eliminarDia(int destinoIndex, int diaIndex) async {
    setState(() {
      _destinos[destinoIndex].dias.removeAt(diaIndex);
    });
    await _guardarDestinos();
  }

  void _agregarActividad(int destinoIndex, int diaIndex) async {
    final nuevaActividad = await _mostrarDialogoActividad();
    if (nuevaActividad != null) {
      setState(() {
        _destinos[destinoIndex].dias[diaIndex].actividades.add(nuevaActividad);
      });
      await _guardarDestinos();
    }
  }

  void _editarActividad(int destinoIndex, int diaIndex, int actIndex) async {
    final actividadActual = _destinos[destinoIndex].dias[diaIndex].actividades[actIndex];
    final actividadEditada = await _mostrarDialogoActividad(actividad: actividadActual);
    if (actividadEditada != null) {
      setState(() {
        _destinos[destinoIndex].dias[diaIndex].actividades[actIndex] = actividadEditada;
      });
      await _guardarDestinos();
    }
  }

  void _eliminarActividad(int destinoIndex, int diaIndex, int actIndex) async {
    setState(() {
      _destinos[destinoIndex].dias[diaIndex].actividades.removeAt(actIndex);
    });
    await _guardarDestinos();
  }

  // --- Métodos de diálogo y toggle ---

  Future<String?> _mostrarDialogoTexto({
    required String titulo,
    String? valorInicial,
  }) {
    final controller = TextEditingController(text: valorInicial ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.writeHere ?? 'Write here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  Future<Color?> _mostrarSelectorColor(Color colorActual) {
    return showDialog<Color>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.selectColor ?? 'Select a color'),
          content: Wrap(
            spacing: 10,
            children: _coloresDisponibles.map((color) {
              bool selected = color == colorActual;
              return GestureDetector(
                onTap: () => Navigator.pop(context, color),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: selected ? Border.all(width: 3, color: Colors.black) : null,
                  ),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 20,
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            )
          ],
        );
      },
    );
  }

  Future<Destino?> _mostrarDialogoDestino({Destino? destino}) async {
    String? ciudad = destino?.ciudad;
    Color color = destino?.color ?? _coloresDisponibles[0];

    final ciudadResult = await _mostrarDialogoTexto(
      titulo: destino == null
          ? AppLocalizations.of(context)?.addCity ?? 'Add city'
          : AppLocalizations.of(context)?.editDestination ?? 'Edit destination',
      valorInicial: ciudad,
    );
    if (ciudadResult == null || ciudadResult.isEmpty) return null;
    ciudad = ciudadResult;

    final colorResult = await _mostrarSelectorColor(color);
    if (colorResult == null) return null;
    color = colorResult;

    return Destino(ciudad: ciudad, dias: destino?.dias ?? [], color: color);
  }

  Future<Dia?> _mostrarDialogoDia({Dia? dia, int? numeroSugerido}) async {
    String? numTexto = dia?.numero.toString() ?? (numeroSugerido?.toString() ?? '');
    final numeroStr = await _mostrarDialogoTexto(
      titulo: dia == null
          ? (AppLocalizations.of(context)?.addDay ?? 'Add day')
          : (AppLocalizations.of(context)?.editDay ?? 'Edit day'),
      valorInicial: numTexto,
    );
    if (numeroStr == null || numeroStr.isEmpty) return null;

    final numero = int.tryParse(numeroStr);
    if (numero == null || numero < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.invalidDayNumber ?? 'Invalid day number')),
      );
      return null;
    }

    return Dia(numero: numero, actividades: dia?.actividades ?? []);
  }

  Future<Actividad?> _mostrarDialogoActividad({Actividad? actividad}) async {
    final descripcion = await _mostrarDialogoTexto(
      titulo: actividad == null
          ? (AppLocalizations.of(context)?.addActivity ?? 'Add activity')
          : (AppLocalizations.of(context)?.editActivity ?? 'Edit activity'),
      valorInicial: actividad?.descripcion,
    );
    if (descripcion == null || descripcion.isEmpty) return null;
    return Actividad(descripcion);
  }

  void _toggleExpandirDestino(int index) {
    setState(() {
      if (_destinosExpandido.contains(index)) {
        _destinosExpandido.remove(index);
      } else {
        _destinosExpandido.add(index);
      }
    });
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Row(
          children: [
            const Icon(Icons.place, color: Colors.white),
            const SizedBox(width: 8),
            Text(localizations.itinerary, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: _destinos.isEmpty
          ? Center(
              child: Text(
                localizations.noDestinationsAdded,
                style: TextStyle(fontSize: 18, color: Colors.indigo.shade800),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _destinos.length,
              itemBuilder: (context, destIndex) {
                final destino = _destinos[destIndex];
                final estaExpandido = _destinosExpandido.contains(destIndex);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _toggleExpandirDestino(destIndex),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: destino.color,
                                    radius: 14,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(destino.ciudad,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: localizations.edit,
                                    onPressed: () => _editarDestino(destIndex),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: localizations.delete,
                                    onPressed: () => _eliminarDestino(destIndex),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (estaExpandido)
                          destino.dias.isEmpty
                              ? Text(localizations.noActivitiesYet)
                              : Column(
                                  children: destino.dias.map((dia) {
                                    return Card(
                                      color: destino.color.withOpacity(0.15),
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('${localizations.day} ${dia.numero}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                                      tooltip: localizations.edit,
                                                      onPressed: () {
                                                        final diaIndex = destino.dias.indexOf(dia);
                                                        _editarDia(destIndex, diaIndex);
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      tooltip: localizations.delete,
                                                      onPressed: () {
                                                        final diaIndex = destino.dias.indexOf(dia);
                                                        _eliminarDia(destIndex, diaIndex);
                                                      },
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            dia.actividades.isEmpty
                                                ? Text(localizations.noActivitiesYet)
                                                : Column(
                                                    children: dia.actividades.map((actividad) {
                                                      final actIndex = dia.actividades.indexOf(actividad);
                                                      return ListTile(
                                                        contentPadding: EdgeInsets.zero,
                                                        title: Text(actividad.descripcion),
                                                        trailing: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.edit, color: Colors.orange),
                                                              tooltip: localizations.edit,
                                                              onPressed: () => _editarActividad(
                                                                  destIndex, destino.dias.indexOf(dia), actIndex),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, color: Colors.red),
                                                              tooltip: localizations.delete,
                                                              onPressed: () => _eliminarActividad(
                                                                  destIndex, destino.dias.indexOf(dia), actIndex),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(
                                                onPressed: () {
                                                  final diaIndex = destino.dias.indexOf(dia);
                                                  _agregarActividad(destIndex, diaIndex);
                                                },
                                                icon: const Icon(Icons.add),
                                                label: Text(localizations.addActivity),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _agregarDia(destIndex),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(localizations.addDay ?? 'Add day'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarDestino,
        backgroundColor: Colors.indigo,
        tooltip: localizations.addNewDestination,
        child: const Icon(Icons.add),
      ),
    );
  }
}
