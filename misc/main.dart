import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import 'chat.pbgrpc.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SendMessageWidget(),
        ),
      ),
    );
  }
}

class SendMessageWidget extends StatefulWidget {
  @override
  _SendMessageWidgetState createState() => _SendMessageWidgetState();
}

class _SendMessageWidgetState extends State<SendMessageWidget> with SingleTickerProviderStateMixin {
  late ClientChannel _channel;
  late ChatServiceClient _stub;
  late StreamController<ChatMessage> _messageController;
  String _responseMessage = '';
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _fontSizeAnimation;
  final AudioPlayer _player = AudioPlayer();


  @override
  void initState() {
    super.initState();
    _initializeGrpcClient();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.blue,
    ).animate(_animationController);

    _fontSizeAnimation = Tween<double>(
      begin: 20,
      end: 40,
    ).animate(_animationController);
  }

  void _initializeGrpcClient() {
    _channel = ClientChannel(
      '10.10.126.85',
      port: 50051,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );

    _stub = ChatServiceClient(_channel);
    _messageController = StreamController<ChatMessage>();
    _startListeningToResponses();

    //发送握手消息
    _sendHandshakeMessage();
  }


  void _sendHandshakeMessage() {
    final handshakeMessage = ChatMessage(
      roomId: '1',
      userName: 'user1',
      message: 'Handshake',
    );
    _messageController.add(handshakeMessage);
  }

  void _startListeningToResponses() async {
    try {
      final responseStream = _stub.sendMessage(_messageController.stream);
      await for (var response in responseStream) {
        setState(() {
          _responseMessage = response.message;
           _colorAnimation = ColorTween(
            begin: const Color.fromARGB(255, 248, 117, 108),
            end: const Color.fromARGB(255, 141, 3, 3),
          ).animate(_animationController);
          _animationController.repeat(reverse: true);
        });
        print('Received response: $_responseMessage'); // 调试信息
        _playAudio();
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error: $e';
      });
      print('Error receiving response: $e'); // 调试信息
    }
  }


  void _playAudio() async {
     try {
      await _player.setAsset('assets/alert_sound.mp3'); // 替换为你的音频文件路径
      _player.setLoopMode(LoopMode.one);
      _player.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }


   void _sendMessage() {
    //final request = ChatMessage()..message = 'Hello, Server!';
    final request = ChatMessage(
      roomId: '1',
      userName: 'user1',
      message: '发生火情!尽快撤离!',
    );
    _messageController.add(request);
    print('add message to stream: ${request.message}'); // 调试信息
    print('Current stream state: ${_messageController.hasListener}'); // 检查流是否有监听器
  }


  @override
  void dispose() {
    _messageController.close();
    _channel.shutdown();
    _animationController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return ElevatedButton(
              onPressed: _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorAnimation.value,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(100), // 调整按钮的大小
              ),
              child: const Text(
                '发现警情',
                style: TextStyle(fontSize: 30),
              ),
            );
          },
        ),
        const SizedBox(height: 80),
        AnimatedBuilder(
          animation: _fontSizeAnimation,
          builder: (context, child) {
            return Text(
              _responseMessage,
              style: TextStyle(
                fontSize: _fontSizeAnimation.value,
                color: Colors.red,
              ),
            );
          },
        ),
      ],
    );
  }
}
