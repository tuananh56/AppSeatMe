import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart' show OptionBuilder;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Thêm ở đầu file nếu chưa có

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

  final String adminId = '686bfd52d27d660c25c71c2c';
  String adminName = "Admin";
  String adminAvatar =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png"; // Avatar Admin

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

  void _connectSocket() {
    socket = IO.io(
      'http://192.168.228.138:5000',
      OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.onConnect((_) {
      socket.emit('join', widget.user?['_id']);
    });

    socket.on('receiveMessage', (data) {
      final newMsg = Map<String, dynamic>.from(data);
      print("📥 Nhận tin nhắn: $newMsg");

      setState(() {
        // Nếu là tin nhắn mình vừa gửi → replace tin nhắn tạm bằng bản chuẩn từ server
        final tempIndex = messages.indexWhere(
          (msg) =>
              msg['isTemp'] == true &&
              msg['message'] == newMsg['message'] &&
              msg['senderId'] == newMsg['senderId'],
        );
        if (tempIndex != -1) {
          messages[tempIndex] = newMsg; // Replace bản chuẩn
        } else {
          // Nếu là tin nhắn mới từ người khác → thêm bình thường
          bool isDuplicate = messages.any((msg) => msg['_id'] == newMsg['_id']);
          if (!isDuplicate) messages.add(newMsg);
        }
      });

      _scrollToBottom();
    });
  }

  Future<void> _fetchChatHistory() async {
    try {
      final userId = widget.user?['_id'];
      final res = await http.get(
        Uri.parse('http://192.168.228.138:5000/api/chat/$userId/$adminId'),
      );

      if (res.statusCode == 200) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("🚨 Exception: $e");
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMsg = {
      '_id': tempId, // ID tạm để quản lý
      'senderId': widget.user?['_id'],
      'receiverId': adminId,
      'message': _messageController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'isTemp': true, // đánh dấu là tin nhắn tạm
    };

    // ✅ Hiển thị ngay tin nhắn tạm
    setState(() {
      messages.add(tempMsg);
    });
    _scrollToBottom();
    _messageController.clear();

    // ✅ Gửi socket lên server
    socket.emit('sendMessage', {
      'senderId': tempMsg['senderId'],
      'receiverId': tempMsg['receiverId'],
      'message': tempMsg['message'],
      'createdAt': tempMsg['createdAt'],
    });
  }

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
    final userAvatar = widget.user?['imageUrl'] != null
        ? "http://192.168.228.138:5000${widget.user?['imageUrl']}"
        : "https://cdn-icons-png.flaticon.com/512/149/149071.png";

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(adminAvatar),
              radius: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                adminName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['senderId'] == widget.user?['_id'];
                final createdAt = msg['createdAt'] != null
                    ? DateTime.tryParse(msg['createdAt'].toString())?.toLocal()
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['message'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm dd/MM/yyyy').format(createdAt),
                            style: TextStyle(
                              fontSize: 12,
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
          Divider(height: 1),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
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
