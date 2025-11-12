import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart' show OptionBuilder;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Import các màn hình khác
import 'package:app_dat_ban/screen/home.dart';
import 'package:app_dat_ban/screen/nearyou.dart';
import 'package:app_dat_ban/screen/search.dart';
import 'package:app_dat_ban/screen/account.dart';
import 'package:app_dat_ban/screen/more.dart';
import 'package:app_dat_ban/screen/admin.dart' as admin;

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

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  final String adminId = '686bfd52d27d660c25c71c2c';
  String adminName = "SeatMe";
  //String adminAvatar = "https://cdn-icons-png.flaticon.com/512/149/149071.png";
  String adminAvatar = "assets/images/logoapp.PNG";

  int _selectedIndex = 0; // 🔥 index mặc định là Home

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
      'http://172.16.217.138:5000',
      OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.onConnect((_) {
      socket.emit('join', widget.user?['_id']);
    });

    socket.on('receiveMessage', (data) {
      final newMsg = Map<String, dynamic>.from(data);
      setState(() {
        final tempIndex = messages.indexWhere(
          (msg) =>
              msg['isTemp'] == true &&
              msg['message'] == newMsg['message'] &&
              msg['senderId'] == newMsg['senderId'],
        );
        if (tempIndex != -1) {
          messages[tempIndex] = newMsg;
        } else if (!messages.any((msg) => msg['_id'] == newMsg['_id'])) {
          messages.add(newMsg);
        }
      });
      _scrollToBottom();
    });
  }

  Future<void> _fetchChatHistory() async {
    try {
      final userId = widget.user?['_id'];
      final res = await http.get(
        Uri.parse('http://172.16.217.138:5000/api/chat/$userId/$adminId'),
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMsg = {
      '_id': tempId,
      'senderId': widget.user?['_id'],
      'receiverId': adminId,
      'message': _messageController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'isTemp': true,
    };
    setState(() => messages.add(tempMsg));
    _scrollToBottom();
    _messageController.clear();

    socket.emit('sendMessage', tempMsg);
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NearYouPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      );
    } else if (index == 4) {
      if (widget.user != null && widget.user!['role'] == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const admin.AdminPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MorePage()),
        );
      }
    }
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
        ? "http://172.16.217.138:5000${widget.user?['imageUrl']}"
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
            CircleAvatar(backgroundImage: AssetImage(adminAvatar), radius: 16),
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

                // 🧠 Kiểm tra ngày mới
                bool isNewDay = false;
                if (index == 0 && createdAt != null) {
                  isNewDay = true;
                } else if (index > 0 && createdAt != null) {
                  final prev = DateTime.tryParse(
                    messages[index - 1]['createdAt'].toString(),
                  )?.toLocal();
                  if (prev != null && !isSameDay(prev, createdAt)) {
                    isNewDay = true;
                  }
                }

                return Column(
                  children: [
                    // 📅 Chèn ngày nếu là ngày mới
                    if (isNewDay)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(createdAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // 📨 Tin nhắn như cũ
                    Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 12),
                            ),
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
                                  fontSize: 14,
                                ),
                              ),
                              if (createdAt != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    DateFormat('HH:mm').format(createdAt),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Divider(height: 1),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 8,
                left: 8,
                right: 8,
                top: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null, // Cho phép xuống dòng tự động
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF004AAD), Color(0xFF00CFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // 🔽 Thêm BottomNavigationBar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6E0000), Color(0xFFFF2323)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.location_pin),
              label: 'Gần bạn',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Tài khoản',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.admin_panel_settings),
              label: (widget.user != null && widget.user!['role'] == 'admin')
                  ? 'Quản trị'
                  : 'Thông tin',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
        ),
      ),
    );
  }
}
