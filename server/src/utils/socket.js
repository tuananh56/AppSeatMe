const Chat = require('../models/Chat'); // Đảm bảo đúng đường dẫn

io.on('connection', (socket) => {
  console.log('🟢 New client connected:', socket.id);

  // Khi người dùng gửi tin nhắn
  socket.on('sendMessage', async (data) => {
    const { senderId, receiverId, message, createdAt } = data;

    console.log('📩 Tin nhắn nhận được:', data);

    // ✅ Lưu tin nhắn vào DB
    try {
      const chat = new Chat({
        senderId,
        receiverId,
        message,
        createdAt: createdAt || new Date(),
      });
      await chat.save();
      console.log('✅ Tin nhắn đã được lưu vào DB:', chat);
    } catch (err) {
      console.error('❌ Lỗi lưu tin nhắn vào DB:', err);
    }

    // ✅ Gửi lại cho người nhận nếu online
    const receiverSocketId = userSocketMap[receiverId];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('receiveMessage', data);
    } else {
      console.warn(`⚠️ Người nhận ${receiverId} chưa online`);
    }
  });

  socket.on('disconnect', () => {
    console.log('🔴 User disconnected:', socket.id);
    // Loại khỏi userSocketMap nếu cần
  });
});
