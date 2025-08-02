const express = require('express');
const router = express.Router();
const Chat = require('../models/Chat');
const User = require('../models/User');

// 📌 Lưu tin nhắn
router.post('/', async (req, res) => {
  try {
    const { senderId, receiverId, message } = req.body;

    console.log('📥 Nhận request lưu chat:', { senderId, receiverId, message });

    if (!senderId || !receiverId || !message) {
      console.warn('⚠️ Thiếu dữ liệu khi lưu chat');
      return res.status(400).json({ error: 'Thiếu thông tin bắt buộc' });
    }

    const chat = new Chat({ senderId, receiverId, message });
    await chat.save();

    console.log('✅ Tin nhắn đã lưu DB:', chat);

    res.status(201).json(chat);
  } catch (err) {
    console.error('❌ Lỗi lưu chat vào DB:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Lấy lịch sử chat giữa 2 user
router.get('/:userId/:otherId', async (req, res) => {
  try {
    const { userId, otherId } = req.params;
    console.log(`📥 Yêu cầu lấy lịch sử chat giữa: ${userId} ↔ ${otherId}`);

    if (!userId || !otherId) {
      console.warn('⚠️ Thiếu userId hoặc otherId khi lấy lịch sử chat');
      return res.status(400).json({ error: 'Thiếu userId hoặc otherId' });
    }

    const messages = await Chat.find({
      $or: [
        { senderId: userId, receiverId: otherId },
        { senderId: otherId, receiverId: userId }
      ]
    }).sort({ createdAt: 1 });

    console.log(`📤 Trả về ${messages.length} tin nhắn giữa ${userId} và ${otherId}`);
    res.json(messages);
  } catch (err) {
    console.error('❌ Lỗi lấy lịch sử chat từ DB:', err);
    res.status(500).json({ error: err.message });
  }
});

/*// 📌 Lấy tất cả các user đã nhắn tin với admin
router.get('/history', async (req, res) => {
  try {
    const adminId = '686bfd52d27d660c25c71c2c'; // ID cố định của admin

    const chats = await Chat.find({
      $or: [{ senderId: adminId }, { receiverId: adminId }]
    }).sort({ createdAt: 1 });

    const grouped = {};

    chats.forEach(chat => {
      const otherId = chat.senderId === adminId ? chat.receiverId : chat.senderId;
      if (!grouped[otherId]) grouped[otherId] = [];
      grouped[otherId].push(chat);
    });

    res.json(grouped);
  } catch (err) {
    console.error('❌ Lỗi lấy lịch sử:', err);
    res.status(500).json({ error: err.message });
  }
});*/
// 📌 Lấy tất cả các user đã nhắn tin với admin, kèm avatar + tên
router.get('/history', async (req, res) => {
  try {
    const adminId = '686bfd52d27d660c25c71c2c'; // ID cố định của admin

    const chats = await Chat.find({
      $or: [{ senderId: adminId }, { receiverId: adminId }]
    }).sort({ createdAt: -1 });

    const grouped = {};
    const userIds = new Set();

    // Gom tin nhắn theo từng userId (khác admin)
    chats.forEach(chat => {
      const otherId = chat.senderId === adminId ? chat.receiverId : chat.senderId;
      userIds.add(otherId);
      if (!grouped[otherId]) grouped[otherId] = [];
      grouped[otherId].push(chat);
    });

    // Truy vấn thông tin user (name + avatar)
    const users = await User.find({ _id: { $in: Array.from(userIds) } })
      .select('name imageUrl'); // Chỉ lấy tên và ảnh

    const userMap = {};
    users.forEach(u => {
      userMap[u._id] = {
        name: u.name,
        imageUrl: u.imageUrl,
      };
    });

    // Kết hợp kết quả trả về
    const result = Object.entries(grouped).map(([userId, messages]) => ({
      userId,
      userInfo: userMap[userId] || { name: 'Không rõ', imageUrl: '' },
      lastMessage: messages[0], // Tin nhắn gần nhất
      messages
    }));

    res.json(result);
  } catch (err) {
    console.error('❌ Lỗi lấy lịch sử:', err);
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
