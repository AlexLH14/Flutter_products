import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool _isCollectingInfo = true;
  Map<String, String> userInfo = {
    'name': '',
    'email': '',
    'country': '',
    'phone': ''
  };
  List<String> projectDetails = [];
  Set<String> askedQuestions = {}; // Para evitar preguntas repetidas

  final String apiKey = "AIzaSyAYPQ0bsnx996_q_lbktXhOhKBs1MLfOL4";
  final String apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent";

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  void _startConversation() {
    setState(() {
      messages.add({
        "role": "assistant",
        "content":
            "¡Hola! Antes de comenzar, proporcióname tu nombre, correo electrónico, pais y numero de telefono"
      });
    });
  }

  Future<void> sendMessage(String userMessage) async {
    setState(() {
      messages.add({"role": "user", "content": userMessage});
    });

    if (_isCollectingInfo) {
      _processUserInfo(userMessage);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$apiUrl?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Eres un asistente especializado en definir proyectos de software, Tu objetivo es hacer preguntas clave para recopilar información sobre el proyecto del usuario. No respondas con código ni términos técnicos avanzados. Dirige la conversación de manera natural hasta tener suficiente información para generar un resumen, Evita hacer preguntas repetitivas y dirige la conversación de manera fluida. Aquí está el historial de preguntas realizadas: ${askedQuestions.join(', ')}. Usuario: $userMessage"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String botMessage =
            data['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          messages.add({"role": "assistant", "content": botMessage});
          askedQuestions.add(botMessage);
          projectDetails.add(userMessage);
        });
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Error en la solicitud: $e");
    }
  }

  void _processUserInfo(String message) {
    List<String> parts = message.split(',');
    if (parts.length >= 3) {
      userInfo['name'] = parts[0].trim();
      userInfo['email'] = parts[1].trim();
      userInfo['country'] = parts[2].trim();
      userInfo['phone'] = parts.length > 3 ? parts[3].trim() : '';

      setState(() {
        _isCollectingInfo = false;
        messages.add({
          "role": "assistant",
          "content":
              "¡Gracias ${userInfo['name']}! Ahora, cuéntame, ¿qué tipo de proyecto tienes en mente?"
        });
      });
    } else {
      setState(() {
        messages.add({
          "role": "assistant",
          "content":
              "Parece que faltan algunos datos. Por favor, proporciona tu nombre, correo y país separados por comas."
        });
      });
    }
  }

  void _endChat() {
    String resumen = "Resumen de la conversación:\n";
    resumen += "- Cliente: ${userInfo['name']}\n";
    resumen += "- Correo: ${userInfo['email']}\n";
    resumen += "- País: ${userInfo['country']}\n";
    resumen += "- Teléfono: ${userInfo['phone']}\n\n";

    // Agregar el resumen del proyecto si ya se generó en la conversación
    String resumenProyecto = generarResumenProyecto();

    if (resumenProyecto.isNotEmpty) {
      resumen += "**Resumen del proyecto:**\n$resumenProyecto\n";
    } else {
      resumen += "**Lo que el cliente necesita:**\n";
      resumen +=
          "El cliente quiere desarrollar un proyecto de software con las siguientes características:\n";
      resumen += "- Información aún incompleta, se requiere más datos.\n";
    }

    // Agregar conclusión
    String conclusion = "**Conclusión:**\n";
    if (resumenProyecto.isNotEmpty) {
      conclusion +=
          "Se recomienda desarrollar el proyecto con base en los requisitos definidos.";
    } else {
      conclusion +=
          "Se requiere un análisis adicional para definir con mayor precisión los objetivos del proyecto.";
    }

    resumen += "\n$conclusion";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Chat Finalizado"),
          content: SingleChildScrollView(child: Text(resumen)),
          actions: [
            TextButton(
              child: Text("Cerrar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // Nueva función para generar el resumen del proyecto desde projectDetails
  String generarResumenProyecto() {
    String tipoProyecto = "";
    String funcionalidades = "";
    String publicoObjetivo = "";
    String flujoTrabajo = "";

    for (var detail in projectDetails) {
      if (detail.contains("app") || detail.contains("plataforma")) {
        tipoProyecto = detail;
      } else if (detail.contains("funciona") ||
          detail.contains("permite") ||
          detail.contains("subir")) {
        funcionalidades += "- $detail\n";
      } else if (detail.contains("publico") ||
          detail.contains("personas") ||
          detail.contains("clientes")) {
        publicoObjetivo = detail;
      } else if (detail.contains("proceso") ||
          detail.contains("flujo") ||
          detail.contains("funciona así")) {
        flujoTrabajo = detail;
      }
    }

    String resumenProyecto = "";
    if (tipoProyecto.isNotEmpty)
      resumenProyecto += "- Tipo de proyecto: $tipoProyecto\n";
    if (funcionalidades.isNotEmpty)
      resumenProyecto += "- Funcionalidades clave:\n$funcionalidades";
    if (publicoObjetivo.isNotEmpty)
      resumenProyecto += "- Público objetivo: $publicoObjetivo\n";
    if (flujoTrabajo.isNotEmpty)
      resumenProyecto += "- Flujo de trabajo: $flujoTrabajo\n";

    return resumenProyecto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat con Asistente")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message["role"] == "user"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message["role"] == "user"
                          ? Colors.blue[200]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(message["content"] ?? ""),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Escribe tu mensaje...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      if (text.isNotEmpty) {
                        sendMessage(text);
                        _controller.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
                TextButton(
                  child: Text("Finalizar Chat"),
                  onPressed: _endChat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
