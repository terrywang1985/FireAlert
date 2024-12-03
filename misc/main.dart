import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'chat.pbgrpc.dart';
import 'chat.pb.dart';
import "dart:async";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _response = '';
  late ChatServiceClient _stub;
  late ClientChannel _channel;
  late StreamController<ChatMessage> _requestStreamController;
  late Stream<ChatMessage> _responseStream;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _channel = ClientChannel(
      '192.168.1.47',
      port: 50051,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    _stub = ChatServiceClient(_channel);
    _requestStreamController = StreamController<ChatMessage>();
    _responseStream = _stub.sendMessage(_requestStreamController.stream);
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _channel.shutdown();
    _requestStreamController.close();
    super.dispose();
  }


  Future<void> _createRoom() async {
    try {
      final response = await _stub.createRoom(CreateRoomRequest()..roomName = _controller.text);
      setState(() {
        _response = 'Created Room ID: ${response.roomId}';
      });
    } catch (e) {
      setState(() {
        _response = 'Caught error: $e';
      });
    }
  }

  void _sendMessage() {
    final message = ChatMessage()
      ..roomId = '1'
      ..userName = 'user'
      ..message = _messageController.text;
      _requestStreamController.add(message);
      _messageController.clear();
  }

  void _playSound() async {
    await _audioPlayer.setAsset('assets/sounds/fire_alert.mp3');
    await _audioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter Room Name',
              ),
            ),
            ElevatedButton(
              onPressed: _createRoom,
              child: const Text('Create Room'),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter Message',
              ),
            ),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send Message'),
            ),
            StreamBuilder<ChatMessage>(
              stream: _responseStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _playSound();
                  return Text('Received: ${snapshot.data!.message}');
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return const Text('Waiting for messages...');
              },
            ),
            Text(_response),
          ],
        ),
      ),
    );
  }
}
