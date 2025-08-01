import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart' show OptionBuilder;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const ChatPage({Key? key, this.user}) : super(key: key);

  @override
  _ChatPageNewState createState() => _ChatPageNewState();
}

class _ChatPageNewState extends State<ChatPage> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];

  // ID Admin lấy từ MongoDB
  final String adminId = '686bfd52d27d660c25c71c2c';

  @override
  void initState() {
    super.initState();
    if (widget.user == null) {
      Future.microtask(() {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Vui lòng đăng nhập để sử dụng chat"),
          ),
        );
      });
    } else {
      _connectSocket();
      _fetchChatHistory();
    }
  }

  /// Kết nối Socket.IO
  void _connectSocket() {
    socket = IO.io(
      'http://192.168.126.138:5000',
      OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.onConnect((_) {
      print('🟢 Connected to chat server');

      // Gửi ID người dùng lên server để định danh
      socket.emit('join', widget.user?['_id']);
    });

    socket.on('receiveMessage', (data) {
      print("📥 Tin nhắn socket: $data");
      setState(() {
        messages.add(Map<String, dynamic>.from(data));
      });
      _scrollToBottom();
    });
  }

  /// Lấy lịch sử chat giữa user và admin
  Future<void> _fetchChatHistory() async {
    try {
      final userId = widget.user?['_id'];
      final res = await http.get(
        Uri.parse('http://192.168.126.138:5000/api/chat/$userId/$adminId'),
      );

      if (res.statusCode == 200) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        });
        _scrollToBottom();
      } else {
        print("❌ Lỗi lấy lịch sử chat: ${res.statusCode}");
      }
    } catch (e) {
      print("🚨 Exception khi load lịch sử chat: $e");
    }
  }

  /// Gửi tin nhắn
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final msg = {
      'senderId': widget.user?['_id'],
      'receiverId': adminId,
      'message': _messageController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(), // để hiển thị ngay
    };

    // Gửi socket để realtime
    socket.emit('sendMessage', msg);

    // Gửi HTTP để lưu DB
    try {
      final res = await http.post(
        Uri.parse('http://192.168.126.138:5000/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': msg['senderId'],
          'receiverId': msg['receiverId'],
          'message': msg['message'],
        }),
      );
      if (res.statusCode != 201) {
        print('❌ Không lưu được tin nhắn vào DB: ${res.body}');
      }
    } catch (e) {
      print('🚨 Lỗi khi gọi API lưu tin nhắn: $e');
    }

    // Hiển thị ngay
    setState(() {
      messages.add(msg);
    });

    _messageController.clear();
    _scrollToBottom();
  }

  /// Cuộn xuống cuối danh sách chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Hỗ trợ')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['senderId'] == widget.user?['_id'];
                final isAdmin = msg['senderId'] == adminId;
                final createdAt = msg['createdAt'] != null
                    ? DateTime.tryParse(msg['createdAt'].toString())
                    : null;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.blue
                          : isAdmin
                          ? Colors.grey[300]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isAdmin) ...[
                          const Text(
                            "Admin",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          msg['message'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
