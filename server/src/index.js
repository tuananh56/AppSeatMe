const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const http = require('http'); // ✅ Phải nằm trước để dùng cho Socket.IO

const app = express();
const server = http.createServer(app); // ✅ Dùng server này cho cả API và socket

// ✅ Socket.IO phải khởi tạo SAU khi có server
const { Server } = require('socket.io');
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

// Models
const Booking = require('./models/Booking');
const Chat = require('./models/Chat');

// Routes
const authRoutes = require('./routes/auth');
const branchRoutes = require('./routes/branch');
const dealRoutes = require('./routes/deal');
const bookingRoutes = require('./routes/booking');
const uploadRoutes = require('./routes/upload');
const qrCodeRoute = require('./routes/qrcode');
const favoriteRoutes = require('./routes/favorite');
const chatRoutes = require('./routes/chat');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Tạo thư mục uploads nếu chưa tồn tại
const uploadPath = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath);
  console.log('📁 Đã tạo thư mục uploads tại:', uploadPath);
}
app.use('/uploads', express.static(uploadPath));

// Kết nối MongoDB
mongoose.connect('mongodb://localhost:27017/app_dat_ban', {
/*  useNewUrlParser: true,b
  useUnifiedTopology: true,*/
})
.then(() => console.log("✅ Kết nối MongoDB thành công"))
.catch((err) => console.error("❌ Kết nối MongoDB thất bại:", err));

// Kiểm tra API gốc
app.get('/', (req, res) => {
  res.send('🚀 API Server đang hoạt động!');
});

// Sử dụng các routes
app.use('/api/auth', authRoutes);
app.use('/api/branches', branchRoutes);
app.use('/api/deals', dealRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/qrcode', qrCodeRoute);
app.use('/api/chat', chatRoutes);

// ------------------ SOCKET.IO CHAT -------------------
const userSocketMap = {}; // userId -> socketId

io.on('connection', (socket) => {
  console.log('🟢 User connected:', socket.id);

  socket.on('join', (userId) => {
    userSocketMap[userId] = socket.id;
    console.log(`✅ User ${userId} joined with socket ${socket.id}`);
  });

  socket.on('sendMessage', async (data) => {
    console.log('📩 Tin nhắn nhận được:', data);

    const chat = new Chat({
      senderId: data.senderId,
      receiverId: data.receiverId,
      message: data.message,
    });
    await chat.save();

    const receiverSocketId = userSocketMap[data.receiverId];
    if (receiverSocketId) {
      io.to(receiverSocketId).emit('receiveMessage', chat);
      console.log(`📤 Gửi tới ${data.receiverId} qua socket ${receiverSocketId}`);
    } else {
      console.log(`⚠️ Người nhận ${data.receiverId} chưa online`);
    }
  });

  socket.on('disconnect', () => {
    for (const [userId, sockId] of Object.entries(userSocketMap)) {
      if (sockId === socket.id) {
        delete userSocketMap[userId];
        console.log(`❌ Xóa user ${userId} khỏi userSocketMap`);
        break;
      }
    }
    console.log('🔴 User disconnected:', socket.id);
  });
});
// -------------------------------------------------------

// Chạy server
const PORT = 5000;
const HOST = '0.0.0.0';
server.listen(PORT, HOST, () => {
  console.log(`🚀 Server đang chạy tại http://${HOST}:${PORT}`);
});
