import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'FavoriteLocationsManager.dart';
import 'overpass_service.dart';

class TablonDeAnunciosScreen extends StatefulWidget {
  final List<dynamic> anuncios;

  TablonDeAnunciosScreen({Key? key, required this.anuncios}) : super(key: key);

  @override
  _TablonDeAnunciosScreenState createState() => _TablonDeAnunciosScreenState();
}

class _TablonDeAnunciosScreenState extends State<TablonDeAnunciosScreen> {
  List<dynamic> _anuncios = [];

  TextEditingController _tituloController = TextEditingController();
  TextEditingController _eventNameController = TextEditingController();
  TextEditingController _fechaController = TextEditingController();
  TextEditingController _numeroPersonasController = TextEditingController();
  TextEditingController _detallesController = TextEditingController();

  DateTime? _selectedDate;
  OSMPlace? _selectedPlace;

  bool _inscribiendose = false;
  int _indexInscripcion = -1;

  @override
  void initState() {
    super.initState();
    _anuncios = widget.anuncios;
  }

  void _mostrarFormularioNuevoAnuncio() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Nuevo Anuncio'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _tituloController,
                        decoration: InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<OSMPlace>(
                        isExpanded: true, // Para hacer el desplegable más grande
                        value: _selectedPlace,
                        onChanged: (OSMPlace? newValue) {
                          setState(() {
                            _selectedPlace = newValue;
                          });
                        },
                        items: FavoriteLocationsManager.favoriteLocations.map((OSMPlace place) {
                          return DropdownMenuItem<OSMPlace>(
                            value: place,
                            child: Text(place.name),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Selecciona un lugar favorito',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _fechaController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                                builder: (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: ThemeData.dark(),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != _selectedDate) {
                                setState(() {
                                  _selectedDate = picked;
                                  _fechaController.text = _formatDate(picked);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _numeroPersonasController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: 'Número de Personas',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _detallesController,
                        decoration: InputDecoration(
                          labelText: 'Detalles',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _limpiarCampos();
                    Navigator.pop(context);
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _todosLosCamposCompletados() ? _guardarAnuncio : null,
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _todosLosCamposCompletados() {
    return _tituloController.text.isNotEmpty &&
        _selectedPlace != null &&
        _fechaController.text.isNotEmpty &&
        _numeroPersonasController.text.isNotEmpty &&
        _detallesController.text.isNotEmpty;
  }

  void _guardarAnuncio() {
    var nuevoAnuncio = {
      'titulo': _tituloController.text,
      'eventName': _eventNameController.text,
      'icono': Icons.event,
      'fecha': _selectedDate ?? DateTime.now(),
      'numeroPersonas': int.tryParse(_numeroPersonasController.text) ?? 0,
      'detalles': _detallesController.text,
      'lugar': _selectedPlace?.name ?? '',
      'inscrito': false, // Añadimos un campo para controlar la inscripción
    };
    setState(() {
      _anuncios.add(nuevoAnuncio);
    });
    _limpiarCampos();
    Navigator.pop(context); // Cerrar el diálogo después de guardar
  }

  void _limpiarCampos() {
    setState(() {
      _tituloController.clear();
      _eventNameController.clear();
      _fechaController.clear();
      _numeroPersonasController.clear();
      _detallesController.clear();
      _selectedDate = null;
      _selectedPlace = null;
    });
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  void _mostrarDetalles(int index) {
    setState(() {
      _anuncios[index]['expanded'] = !(_anuncios[index]['expanded'] ?? false);
    });
  }

  void _mostrarDialogoInscripcion(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Inscripción'),
          content: Text('¿Estás seguro de que quieres inscribirte en este evento?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _inscribirse(index);
                Navigator.pop(context);
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _inscribirse(int index) {
    setState(() {
      _anuncios[index]['inscrito'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true, // Centra el título
        title: Text(
          'Anouncements board',
          style: TextStyle(color: Colors.deepOrange),
        ),
      ),
      body: _anuncios.isEmpty
          ? Center(
        child: Text('no anouncements yet!'),
      )
          : ListView.builder(
        itemCount: _anuncios.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200], // Fondo gris claro para cada anuncio
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _mostrarDetalles(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _anuncios[index]['titulo'],
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            _anuncios[index]['inscrito'] ? Icons.check_circle : Icons.event,
                            color: _anuncios[index]['inscrito'] ? Colors.green : Colors.grey,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fecha: ${_anuncios[index]['fecha'].day}/${_anuncios[index]['fecha'].month}/${_anuncios[index]['fecha'].year} - ${_anuncios[index]['numeroPersonas']} personas',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (_anuncios[index]['expanded'] ?? false)
                        Text(
                          'Detalles: ${_anuncios[index]['detalles']}',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
                if (_anuncios[index]['expanded'] ?? false && !_anuncios[index]['inscrito'])
                  ElevatedButton(
                    onPressed: () => _mostrarDialogoInscripcion(index),
                    child: Text('Inscribirse'),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioNuevoAnuncio,
        backgroundColor: Colors.deepOrange,
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
