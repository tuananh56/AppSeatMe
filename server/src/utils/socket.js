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

    // ✅ Emit lại bản chuẩn cho người gửi & người nhận
    const fullMsg = chat.toObject();
    io.to(socket.id).emit('receiveMessage', fullMsg); // Người gửi
    const receiverSocketId = userSocketMap[receiverId];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('receiveMessage', fullMsg); // Người nhận
    }
  } catch (err) {
    console.error('❌ Lỗi lưu tin nhắn:', err);
  }
});
