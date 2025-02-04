import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FloatingChat extends StatefulWidget {
  @override
  _FloatingChatState createState() => _FloatingChatState();
}

class _FloatingChatState extends State<FloatingChat> {
  bool isOpen = false;
  bool isMinimized = false;
  Offset position = Offset(250, 500); // Posición inicial del botón
  double chatWidth = 350;
  double chatHeight = 450;
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
  Set<String> askedQuestions = {};

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
            "¡Hola! Antes de comenzar, proporcióname tu nombre, correo electrónico, país y número de teléfono."
      });
    });
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": userMessage});
      _controller.clear();
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
              "Parece que faltan algunos datos. Proporciona tu nombre, correo y país separados por comas."
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                position = Offset(
                  (position.dx + details.delta.dx).clamp(
                      0.0, MediaQuery.of(context).size.width - chatWidth),
                  (position.dy + details.delta.dy).clamp(
                      0.0, MediaQuery.of(context).size.height - chatHeight),
                );
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOpen)
                  GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        chatWidth += details.delta.dx;
                        chatHeight += details.delta.dy;
                        chatWidth = chatWidth.clamp(300, 500);
                        chatHeight = chatHeight.clamp(350, 700);
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: chatWidth,
                      height: isMinimized ? 50 : chatHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10)
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(15)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Asesor Virtual",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                          isMinimized
                                              ? Icons.open_in_full
                                              : Icons.minimize,
                                          color: Colors.white),
                                      onPressed: () => setState(
                                          () => isMinimized = !isMinimized),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.white),
                                      onPressed: () =>
                                          setState(() => isOpen = false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isMinimized)
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
                          if (!isMinimized)
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      decoration: InputDecoration(
                                        hintText: "Escribe un mensaje...",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.send, color: Colors.blue),
                                    onPressed: () =>
                                        sendMessage(_controller.text),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                FloatingActionButton(
                  backgroundColor: Colors.blue,
                  child: Icon(isOpen ? Icons.close : Icons.chat),
                  onPressed: () => setState(() {
                    isOpen = !isOpen;
                    isMinimized = false;
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
