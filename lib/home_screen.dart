import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:gemini_chat/widget/line.dart';
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
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "gemini");
  ChatUser geminiUser2 = ChatUser(id: "2", firstName: "gemini2");
  
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
        backgroundColor: const Color.fromARGB(255, 106, 13, 173),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Gemini Chatbox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Spacer(),
            IconButton(
              onPressed: () {refreshPage();}, 
              icon: Icon(Icons.refresh), color: Colors.white,)
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
        trailing: [IconButton(
          onPressed: () {
          stt.isNotListening 
            ? startListening() 
            : stopListening();
        }, icon: Icon(
          stt.isNotListening 
            ? Icons.mic 
            : Icons.mic_off,
            color: const Color.fromARGB(255, 106, 13, 173),
          ))
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
              Line(),
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
  // Cái hàm này có thể dùng để sử lí message từ người dùng
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
    // Cho Streaming message lên đầu danh sách
    // Tức là: message[0] = streamingMessage, streamingMessage ở vị trí index số 0 trong list Message
    // dư liệu luôn được truyền vào vị trí index số 0
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
      // Khi nhận được chunk từ gemini, thì ghi đè lên phần tử đầu tiên 
      // first.text = text đã có (đã nhận từ trước) VD: hello wor rồi cộng thêm chunk "ld"
      // chunk = phần text mới Streaming mang về
      // messages[0] bị thay thế bời 1 chatMessages mới chứa text cộng dồn
      setState(() {
        // ChatMessage first = messages[0] (2 cách này dống nhau nhưng dùng .first cho ngắn và an toàn hơn.)
        // cơ bản là đang lấy phần tử đầu của messages, trong khi đó phần tử đầu lại đang là streamingMessage suy ra
        // messages.first == StreamingMessage
        // message.firts giúp:
        // đọc nội dung  hiện tại của tin nhắn đang được streaming
        // nối thêm chunk mới vào
        // ChatMessage first = messages.first; // first.text = ""
        // messages[0] = ChatMessage(text: first.text + "Hel"); // => "Hel" hel là chunk mới nhận đc
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

  