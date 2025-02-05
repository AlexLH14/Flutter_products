import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'screens/product_details_page.dart';
import 'screens/add_product.dart';
import 'screens/edit_product.dart';
import 'widgets/floating_chat.dart';
import 'widgets/export_excel_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Products',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: ProductListPage(
        onThemeToggle: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
      ),
    );
  }
}

class ProductListPage extends StatelessWidget {
  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');
  final VoidCallback onThemeToggle;

  ProductListPage({required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Productos'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          ExportExcelButton(), // Agrega el botón de descarga aquí
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) => onThemeToggle(),
          ),
        ],
      ),
      body: Stack(
        // Aquí usamos Stack para colocar el chat flotante sobre el contenido
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: products.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final productDocs = snapshot.data!.docs;

              if (productDocs.isEmpty) {
                return Center(
                  child: Text(
                    'No hay productos disponibles.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: kIsWeb ? 4 : 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: productDocs.length,
                itemBuilder: (context, index) {
                  final product =
                      productDocs[index].data() as Map<String, dynamic>;
                  final productId = productDocs[index].id;

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(10)),
                            child: Container(
                              color: Colors.grey[200],
                              child: product['imageUrl'] != null
                                  ? Image.network(
                                      product['imageUrl'],
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.broken_image,
                                            size: 50, color: Colors.red);
                                      },
                                    )
                                  : Icon(Icons.image_not_supported,
                                      size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product['name'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            'Precio: \$${product['price']}',
                            style: TextStyle(
                                fontSize: 16, color: Colors.green[700]),
                          ),
                        ),
                        ButtonBar(
                          alignment: MainAxisAlignment.spaceBetween,
                          buttonPadding: EdgeInsets.zero,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.green),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsPage(
                                      name: product['name'],
                                      price: product['price'],
                                      description: product['description'],
                                      imageUrl: product['imageUrl'],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProductPage(
                                      productId: productId,
                                      product: product,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await products.doc(productId).delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Producto eliminado correctamente')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error al eliminar producto: $e')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          FloatingChat(), // Agregamos el chat flotante aquí
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
        },
      ),
    );
  }
}
