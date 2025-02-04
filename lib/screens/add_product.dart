import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gcs_service.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  File? _imageFile;
  Uint8List? _webImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    final description = descriptionController.text.trim();

    if (name.isNotEmpty &&
        price > 0 &&
        description.isNotEmpty &&
        (_imageFile != null || _webImage != null)) {
      setState(() {
        _isUploading = true;
      });

      try {
        String? imageUrl;
        if (kIsWeb && _webImage != null) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
          imageUrl = await GCSService.uploadImageWeb(_webImage!, fileName);
        } else if (_imageFile != null) {
          imageUrl = await GCSService.uploadImage(_imageFile!);
        }

        if (imageUrl != null) {
          await products.add({
            'name': name,
            'price': price,
            'description': description,
            'imageUrl': imageUrl,
          });

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al subir la imagen. Inténtalo de nuevo.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Todos los campos y la imagen son obligatorios.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Producto'),
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
                    // Campo de nombre
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Campo de precio
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Precio *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    // Campo de descripción
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Imagen
                    Center(
                      child: Column(
                        children: [
                          _webImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(_webImage!,
                                      height: 150,
                                      width: 150,
                                      fit: BoxFit.cover),
                                )
                              : _imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(_imageFile!,
                                          height: 150,
                                          width: 150,
                                          fit: BoxFit.cover),
                                    )
                                  : Icon(Icons.image,
                                      size: 100, color: Colors.grey),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: Icon(Icons.image),
                            label: Text(
                              _webImage != null || _imageFile != null
                                  ? 'Cambiar Imagen'
                                  : 'Seleccionar Imagen',
                            ),
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Botón Guardar
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text(_isUploading ? 'Cargando...' : 'Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isUploading ? null : _saveProduct,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
