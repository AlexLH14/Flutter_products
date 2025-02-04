import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gcs_service.dart';

class EditProductPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  EditProductPage({required this.productId, required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  File? _newImage;
  Uint8List? _webImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name']);
    priceController =
        TextEditingController(text: widget.product['price'].toString());
    descriptionController =
        TextEditingController(text: widget.product['description']);
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _newImage = null;
        });
      } else {
        setState(() {
          _newImage = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _updateProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final description = descriptionController.text.trim();

    if (name.isNotEmpty && price > 0 && description.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      try {
        String? imageUrl = widget.product['imageUrl'];

        if (_webImage != null) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
          imageUrl = await GCSService.uploadImageWeb(_webImage!, fileName);
        } else if (_newImage != null) {
          final oldImagePath =
              Uri.parse(widget.product['imageUrl']).pathSegments.last;
          await GCSService.deleteImage('images/$oldImagePath');
          imageUrl = await GCSService.uploadImage(_newImage!);
        }

        await products.doc(widget.productId).update({
          'name': name,
          'price': price,
          'description': description,
          'imageUrl': imageUrl,
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar producto: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todos los campos son obligatorios')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de Nombre
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 96, 167, 233),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Campo de Precio
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Precio *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 96, 167, 233),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    // Campo de Descripción
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 96, 167, 233),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Imagen
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 200, // Altura fija
                            width:
                                double.infinity, // Ocupa todo el ancho posible
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: _webImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      _webImage!,
                                      fit: BoxFit
                                          .contain, // La imagen se ajusta dentro del espacio
                                    ),
                                  )
                                : _newImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _newImage!,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : widget.product['imageUrl'] != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              widget.product['imageUrl'],
                                              fit: BoxFit.contain,
                                            ),
                                          )
                                        : Center(
                                            child: Icon(Icons.image,
                                                size: 50, color: Colors.grey),
                                          ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            icon: Icon(Icons.image, color: Colors.blue),
                            label: Text('Seleccionar Imagen'),
                            onPressed: _pickImage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Botón de Actualizar
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text(_isUploading ? 'Actualizando...' : 'Actualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(155, 35, 209, 29),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isUploading ? null : _updateProduct,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
