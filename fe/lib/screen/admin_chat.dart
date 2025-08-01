import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart' show OptionBuilder;

class AdminChatPage extends StatefulWidget {
  const AdminChatPage({Key? key}) : super(key: key);

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  late IO.Socket socket;
  Map<String, List<Map<String, dynamic>>> userMessages = {};
  Map<String, String> userAvatars = {}; // userId -> avatarUrl
  String? selectedUserId;
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = true;

  final String adminId = '686bfd52d27d660c25c71c2c';

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _loadChatHistory();
  }

  void _connectSocket() {
    socket = IO.io(
      'http://192.168.126.138:5000',
      OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.onConnect((_) {
      print('🟢 Admin connected to chat server');
    });

    socket.on('receiveMessage', (data) {
      final msg = Map<String, dynamic>.from(data);
      final userId = msg['senderId'];

      setState(() {
        if (!userMessages.containsKey(userId)) {
          userMessages[userId] = [];
        }
        userMessages[userId]!.add(msg);
        selectedUserId ??= userId;
      });

      _fetchUserAvatar(userId);
    });
  }

  Future<void> _fetchUserAvatar(String userId) async {
    if (userAvatars.containsKey(userId)) return;
    try {
      final res = await http.get(Uri.parse('http://192.168.126.138:5000/api/users/$userId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          userAvatars[userId] = data['avatar'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.126.138:5000/api/chat/history'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, List<dynamic>> rawMessages = Map<String, List<dynamic>>.from(data);

        final Map<String, List<Map<String, dynamic>>> loadedMessages = {};
        rawMessages.forEach((userId, msgs) {
          loadedMessages[userId] = msgs.map((e) => Map<String, dynamic>.from(e)).toList();
          _fetchUserAvatar(userId);
        });

        setState(() {
          userMessages = loadedMessages;
          selectedUserId = userMessages.keys.isNotEmpty ? userMessages.keys.first : null;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading chat history: $e');
    }
  }

  void _sendMessage() {
    if (selectedUserId == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final msg = {
      'senderId': adminId,
      'receiverId': selectedUserId,
      'message': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    socket.emit('sendMessage', msg);

    setState(() {
      userMessages[selectedUserId]!.add(msg);
    });

    _messageController.clear();
  }

  Widget _buildUserList() {
    return Container(
      width: 120,
      color: Colors.grey[200],
      child: ListView(
        children: userMessages.keys.map((userId) {
          final avatar = userAvatars[userId];
          return ListTile(
            selected: userId == selectedUserId,
            leading: CircleAvatar(
              radius: 18,
              backgroundImage:
                  avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar == null || avatar.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(userId, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => setState(() => selectedUserId = userId),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatMessages() {
    if (selectedUserId == null) return const Center(child: Text('Chưa có cuộc trò chuyện nào'));
    final messages = userMessages[selectedUserId] ?? [];

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[messages.length - 1 - index];
        final isAdmin = msg['senderId'] == adminId;
        final avatarUrl = isAdmin ? null : userAvatars[msg['senderId']];

        return Row(
          mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isAdmin)
              CircleAvatar(
                radius: 16,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person, size: 16) : null,
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                msg['message'] ?? '',
                style: TextStyle(color: isAdmin ? Colors.white : Colors.black),
              ),
            ),
            if (isAdmin)
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    socket.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Chat')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                _buildUserList(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildChatMessages()),
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
                                minLines: 1,
                                maxLines: 5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
