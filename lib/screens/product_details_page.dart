import 'package:flutter/material.dart';

class ProductDetailsPage extends StatelessWidget {
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  ProductDetailsPage({
    required this.name,
    required num price, // Acepta tanto int como double
    required this.description,
    required this.imageUrl,
  }) : price = price.toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 7, 184, 207),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen centrada
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), // Bordes redondeados.
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1), // Sombra suave.
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      width: MediaQuery.of(context).size.width *
                          0.8, // 80% del ancho
                      height: MediaQuery.of(context).size.height *
                          0.4, // 40% del alto
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image,
                            size: 100, color: Colors.red);
                      },
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
              // Nombre del producto
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              // Precio del producto
              Text(
                'Precio: \$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 20),
              // Descripción
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 100, 184, 233),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 16,
                          color: const Color.fromARGB(255, 17, 14, 197)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
