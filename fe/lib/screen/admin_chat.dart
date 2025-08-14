import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'nearyou.dart';
import 'home.dart';
import 'search.dart';
import 'account.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
//import 'package:intl/intl.dart'; // Thêm ở đầu file nếu chưa có

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  late IO.Socket socket;
  String adminId = '686bfd52d27d660c25c71c2c'; // ID cố định của admin
  String? selectedUserId;

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, List<dynamic>> userMessages = {}; // userId -> list of messages
  Map<String, String> userAvatars = {}; // userId -> avatar URL
  Map<String, String> userNames = {}; // userId -> name

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _fetchChatHistory();
  }

  @override
  void dispose() {
    socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectSocket() {
    socket = IO.io(
      'http://192.168.228.138:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Socket connected');
      socket.emit('join', adminId);
      //socket.emit('registerUser', adminId); // Đăng ký adminId cho server
    });

    socket.on('receiveMessage', (data) {
      final newMsg = Map<String, dynamic>.from(data);

      // ✅ Kiểm tra tin nhắn trùng
      bool isDuplicate =
          userMessages[newMsg['senderId']]?.any(
            (msg) =>
                msg['message'] == newMsg['message'] &&
                msg['senderId'] == newMsg['senderId'] &&
                msg['createdAt'] == newMsg['createdAt'],
          ) ??
          false;

      if (!isDuplicate) {
        setState(() {
          userMessages.putIfAbsent(newMsg['senderId'], () => []);
          userMessages[newMsg['senderId']]!.add(newMsg);
        });
      }
    });

    socket.onDisconnect((_) => print('Socket disconnected'));
  }

  Future<void> _fetchChatHistory() async {
    try {
      final res = await http.get(
        Uri.parse('http://192.168.228.138:5000/api/chat/history'),
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        // ✅ Xoá dữ liệu cũ trước khi load mới
        setState(() {
          userMessages.clear();
          userNames.clear();
          userAvatars.clear();
        });

        // ✅ Duyệt qua từng user trong danh sách trả về
        for (var item in data) {
          final String userId = item['userId'];
          final Map<String, dynamic> userInfo = item['userInfo'] ?? {};
          final List<dynamic> messages = List.from(item['messages'] ?? []);

          userMessages[userId] = messages;
          userNames[userId] = userInfo['name'] ?? 'Ẩn danh';
          userAvatars[userId] =
              (userInfo['imageUrl'] != null &&
                  userInfo['imageUrl'].toString().isNotEmpty)
              ? 'http://192.168.228.138:5000${userInfo['imageUrl']}'
              : '';
        }

        // ✅ Auto chọn user đầu tiên
        if (data.isNotEmpty) {
          setState(() {
            selectedUserId = data.first['userId'];
          });
        }
      }
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  /* Future<void> _fetchUserAvatar(String userId) async {
    if (userAvatars.containsKey(userId)) return;

    try {
      final res = await http.get(
        Uri.parse('http://192.168.228.138:5000/api/users/$userId'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          userAvatars[userId] = data['imageUrl'] != null
              ? 'http://192.168.228.138:5000${data['imageUrl']}'.replaceFirst(
                  '//',
                  '/',
                )
              : '';
          userNames[userId] = data['name'] ?? 'Ẩn danh';
        });
      }
    } catch (e) {
      print('Error fetching avatar: $e');
    }
  }*/

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || selectedUserId == null) return;

    final message = {
      'senderId': adminId,
      'receiverId': selectedUserId,
      'message': text,
      'createdAt': DateTime.now()
          .toIso8601String(), // ⚠ Đổi "timestamp" thành "createdAt" cho đồng bộ với BE
      'localIndex': DateTime.now().microsecondsSinceEpoch, // 🔥 luôn tăng
      'isTemp': true,
    };

    // Gửi qua socket
    socket.emit('sendMessage', message);

    // Thêm ngay vào UI
    setState(() {
      userMessages[selectedUserId]!.add(message);

      // Sắp xếp lại theo thời gian
      userMessages[selectedUserId]!.sort((a, b) {
        return DateTime.parse(
          a['createdAt'],
        ).compareTo(DateTime.parse(b['createdAt']));
      });

      _messageController.clear();
    });

    // Tự động scroll xuống cuối
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildUserList() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6E0000), // Đỏ đậm
            Color(0xFFFF2323), // Đỏ sáng
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        children: userMessages.keys.map((userId) {
          final avatar = userAvatars[userId] ?? '';
          final name = userNames[userId] ?? 'Ẩn danh';
          final lastMsg = (userMessages[userId]?.isNotEmpty ?? false)
              ? userMessages[userId]!.last['message']
              : '';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedUserId == userId
                      ? [
                          Color(0xFF004AAD),
                          Color(0xFF00CFFF),
                        ] // 🌟 Khi được chọn
                      : [Color(0xFF6E0000), Color(0xFFFF2323)], // 🔴 Mặc định
                ),
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            subtitle: Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            onTap: () {
              setState(() {
                selectedUserId = userId;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessages() {
    // Copy danh sách tin nhắn để tránh thay đổi trực tiếp dữ liệu gốc
    final messages = [...(userMessages[selectedUserId] ?? [])];

    // 🔥 Sắp xếp tin nhắn theo thời gian (cũ -> mới)
    messages.sort((a, b) {
      final timeA =
          DateTime.tryParse(a['createdAt'] ?? a['timestamp'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final timeB =
          DateTime.tryParse(b['createdAt'] ?? b['timestamp'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);

      /*if (timeA.isBefore(timeB)) return -1;
      if (timeA.isAfter(timeB)) return 1;

      // Nếu thời gian bằng nhau, giữ nguyên thứ tự theo lúc thêm vào
      return 0; // Không dùng so sánh id nữa*/
      return timeA.compareTo(timeB); // sắp xếp tăng dần theo thời gian
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['senderId'] == adminId;

                final dateTime =
                    DateTime.tryParse(
                      msg['createdAt'] ?? msg['timestamp'] ?? '',
                    )?.toLocal() ??
                    DateTime.now();

                final previousMsg = index > 0 ? messages[index - 1] : null;
                final previousDate = previousMsg != null
                    ? DateTime.tryParse(
                        previousMsg['createdAt'] ??
                            previousMsg['timestamp'] ??
                            '',
                      )?.toLocal()
                    : null;

                final showDateHeader =
                    previousDate == null || !isSameDay(dateTime, previousDate);

                return Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(dateTime),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[600] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['message'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(dateTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  const SizedBox(width: 6),
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () =>
                    Scaffold.of(context).openDrawer(), // ✅ Fix context
              ),
            ),
            const SizedBox(width: 8),
            if (selectedUserId != null &&
                userAvatars[selectedUserId]?.isNotEmpty == true)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(userAvatars[selectedUserId]!),
              ),
            if (selectedUserId != null &&
                userAvatars[selectedUserId]?.isNotEmpty == true)
              const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedUserId != null
                    ? userNames[selectedUserId] ?? 'Hỗ trợ khách hàng'
                    : 'Chọn người dùng',
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

      drawer: Drawer(
        child: _buildUserList(), // Danh sách khách hàng
      ),
      body: selectedUserId == null
          ? Center(child: Text('Chọn một người dùng để bắt đầu trò chuyện'))
          : _buildMessages(),

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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_pin),
              label: 'Gần bạn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Tài khoản',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Quản trị',
            ),
          ],
          currentIndex: 4, // Tab mặc định cho Admin
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePage(user: null),
                ), // 👈 truyền user nếu có
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
              // đang ở admin thì không làm gì
            }
          },

          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
        ),
      ),
    );
  }
}
