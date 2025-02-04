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

  // 🔑 Reemplaza con tu clave API de Google Gemini
  final String apiKey = "AIzaSyAYPQ0bsnx996_q_lbktXhOhKBs1MLfOL4";

  Future<void> sendMessage(String userMessage) async {
    setState(() {
      messages.add({"role": "user", "content": userMessage});
    });

    const String apiUrl =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent";

    try {
      final response = await http.post(
        Uri.parse("$apiUrl?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": userMessage}
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
        });
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Error en la solicitud: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat con Google Gemini")),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
