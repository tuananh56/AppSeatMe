const userSocketMap = {}; // userId -> socketId

io.on('connection', (socket) => {
  console.log('🟢 Client connected:', socket.id);

  // Khi user hoặc admin đăng ký socketId
  socket.on('registerUser', (userId) => {
    userSocketMap[userId] = socket.id;
    console.log(`📌 ${userId} đã đăng ký socketId: ${socket.id}`);
  });

  // Nhận tin nhắn từ client
  socket.on('sendMessage', async (data) => {
    const { senderId, receiverId, message, createdAt } = data;
    console.log('📩 Tin nhắn nhận được:', data);

    try {
      // ✅ Lưu DB
      const chat = new Chat({
        senderId,
        receiverId,
        message,
        createdAt: createdAt || new Date(),
      });
      await chat.save();

      console.log('✅ Tin nhắn đã lưu DB:', chat);

      // ✅ Bản tin chuẩn để emit lại
      const fullMsg = chat.toObject();

      // Gửi cho người gửi
      const senderSocketId = userSocketMap[senderId];
      if (senderSocketId) {
        io.to(senderSocketId).emit('receiveMessage', fullMsg);
      }

      // Gửi cho người nhận
      const receiverSocketId = userSocketMap[receiverId];
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('receiveMessage', fullMsg);
      }
    } catch (err) {
      console.error('❌ Lỗi lưu tin nhắn:', err);
    }
  });

  // Khi disconnect thì xoá socketId
  socket.on('disconnect', () => {
    for (const userId in userSocketMap) {
      if (userSocketMap[userId] === socket.id) {
        delete userSocketMap[userId];
        console.log(`🔴 ${userId} đã ngắt kết nối`);
        break;
      }
    }
  });
});
