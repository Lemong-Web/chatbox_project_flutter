import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];
  List<ChatUser> typingUsers = [];

  SpeechToText stt = SpeechToText();
  FlutterTts tts = FlutterTts();
  TextEditingController chatController = TextEditingController();
  bool speechEnable = false;
  String lastword = "";
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "gemini");
  
  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    speechEnable = await stt.initialize();
    setState(() {}); 
  }

  void startListening() async {
    if (speechEnable) {
      stt.listen(
        onResult: (result) {
          setState(() {
            chatController.text = result.recognizedWords;
          });
        }
      );
    }
    setState(() {});
  }
  void stopListening() async {
    await stt.stop();
    setState(() {});
  }

  void refreshPage() {
    setState(() {
      messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GEMINI CHATBOX', style: TextStyle(color: Colors.white)),
            Spacer(),
            IconButton(
              onPressed: () {refreshPage();}, 
              icon: Icon(Icons.refresh))
          ],
        )
      ),
      body: _buildUI(),
    );
  }
  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(
        textController: chatController,
        alwaysShowSend: true,
        trailing: [IconButton(onPressed: () {
          stt.isNotListening 
            ? startListening() 
            : stopListening();
        }, icon: Icon(
          stt.isNotListening 
            ? Icons.mic 
            : Icons.mic_off))
        ]),
      currentUser: currentUser, 
      onSend: _sendMessage, 
      messages: messages,
      typingUsers: typingUsers,
      messageOptions: MessageOptions(
        messageTextBuilder: (message, previousMessage, nextMessage)  {
          if (message.user.id == geminiUser.id) {
            return Column(
            children: [
                  Text(
                  message.text,
                  style: const TextStyle(fontSize: 16),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    tts.speak(message.text);
                  }, 
                  icon: Icon(Icons.voice_chat, size: 20)),
              )
              ],
            );
          }
          return Text(
            message.text,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          );
        },
      ),
    );
  }
  
  void _sendMessage(ChatMessage chatMessage) {
  setState(() {
    typingUsers = [geminiUser];
    messages = [chatMessage, ...messages];
  });

  try {
    String question = chatMessage.text;
    ChatMessage streamingMessage = ChatMessage(
      user: geminiUser,
      createdAt: DateTime.now(),
      text: "",
    );
    setState(() {
      messages = [streamingMessage, ...messages];
    });
    // ignore: deprecated_member_use
    gemini.streamGenerateContent(question).listen((event) {
      String chunk = event.content?.parts
        ?.whereType<TextPart>()
        .map((p) => p.text)
        .join(" ")
        .replaceAll(RegExp(r'\*+'), "")
        .trim() ??
        "";
      setState(() {
        ChatMessage first = messages.first;
        typingUsers = [];
        messages[0] = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: first.text + chunk,
        );
      });
    });
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }
}

  