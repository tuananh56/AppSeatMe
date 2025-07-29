const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

// Models
const Booking = require('./models/Booking');

// Routes
const authRoutes = require('./routes/auth');
const branchRoutes = require('./routes/branch');
const dealRoutes = require('./routes/deal');
const bookingRoutes = require('./routes/booking');
const uploadRoutes = require('./routes/upload');
const qrCodeRoute = require('./routes/qrcode');
const favoriteRoutes = require('./routes/favorite');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Tạo thư mục uploads nếu chưa tồn tại (ở cấp src/../uploads)
const uploadPath = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath);
  console.log('📁 Đã tạo thư mục uploads tại:', uploadPath);
}

// Phục vụ file ảnh tĩnh
app.use('/uploads', express.static(uploadPath));

// Kết nối MongoDB
mongoose.connect('mongodb://localhost:27017/app_dat_ban', {
 useNewUrlParser: true,
useUnifiedTopology: true,
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
app.use('/api/bookings', bookingRoutes); // booking routes chính
app.use('/api/favorites', favoriteRoutes);
app.use('/api/qrcode', qrCodeRoute);



// Kiểm tra enum booking (nếu cần debug)
console.log('🧪 Enum hiện tại:', Booking.schema.path('trangThaiXacNhan').enumValues);

// Chạy server
const PORT = 5000;
const HOST = '0.0.0.0';
app.listen(PORT, HOST, () => {
  console.log(`🚀 Server đang chạy tại http://${HOST}:${PORT}`);
});
