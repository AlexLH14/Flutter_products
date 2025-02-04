import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Para detectar Web
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/storage/v1.dart' as gcs;

class GCSService {
  static const _bucketName = 'flutter-products-test';

  // Método para subir imágenes en Android/iOS
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final credentialsJson =
          await rootBundle.loadString('service_account_key.json');
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);

      final httpClient = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );

      final storage = gcs.StorageApi(httpClient);

      final media = gcs.Media(imageFile.openRead(), imageFile.lengthSync());
      final objectName = 'images/${imageFile.uri.pathSegments.last}';
      //final uploadedObject = await storage.objects.insert(
      await storage.objects.insert(
        gcs.Object()..name = objectName,
        _bucketName,
        uploadMedia: media,
      );

      httpClient.close();

      return 'https://storage.googleapis.com/$_bucketName/$objectName';
    } catch (e) {
      print('Error al subir la imagen a GCS: $e');
      return null;
    }
  }

  // Método para subir imágenes en Web
  static Future<String?> uploadImageWeb(
      Uint8List imageBytes, String fileName) async {
    try {
      final credentialsJson =
          await rootBundle.loadString('service_account_key.json');
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);

      final httpClient = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );

      final url = Uri.parse(
          'https://storage.googleapis.com/upload/storage/v1/b/$_bucketName/o?uploadType=media&name=images/$fileName');

      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Bearer ${(await httpClient.credentials).accessToken.data}',
          'Content-Type': 'application/octet-stream',
        },
        body: imageBytes,
      );

      httpClient.close();

      if (response.statusCode == 200) {
        return 'https://storage.googleapis.com/$_bucketName/images/$fileName';
      } else {
        print('Error al subir la imagen: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error al subir la imagen en Web: $e');
      return null;
    }
  }

  static Future<bool> deleteImage(String imagePath) async {
    try {
      final credentialsJson =
          await rootBundle.loadString('service_account_key.json');
      final credentials = ServiceAccountCredentials.fromJson(credentialsJson);

      final httpClient = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );

      final storage = gcs.StorageApi(httpClient);

      final objectName = imagePath.split('/').last;
      await storage.objects.delete(_bucketName, 'images/$objectName');

      httpClient.close();
      print('Imagen eliminada correctamente: $imagePath');
      return true;
    } catch (e) {
      print('Error al eliminar la imagen de GCS: $e');
      return false;
    }
  }
}
