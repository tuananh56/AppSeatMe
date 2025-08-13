const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const otpStore = {}; // Dùng tạm trong RAM, nếu cần bền vững thì dùng DB

const Otp = require('../models/Otp');
const sendEmail = require('../utils/sendEmail');
const crypto = require('crypto');

// Cấu hình multer lưu ảnh
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/'); // Thư mục lưu ảnh
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname)); // tên file duy nhất
  }
});

const upload = multer({ storage: storage });

// Route đăng ký có upload ảnh
router.post('/register', upload.single('image'), async (req, res) => {
  try {
    console.log('📥 Body nhận được:', req.body);
    console.log('📥 File nhận được:', req.file);

    const { name, email, password, confirmPassword, phone } = req.body;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    if (!name || !email || !password || !confirmPassword || !phone || !imageUrl) {
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin và upload ảnh' });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({ message: 'Mật khẩu và xác nhận không khớp' });
    }

    // Kiểm tra email đã tồn tại chưa
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email đã được sử dụng' });
    }

    // Đếm người dùng để phân quyền
    const userCount = await User.countDocuments();
    const assignedRole = userCount === 0 ? 'admin' : 'user';

    // Mã hóa mật khẩu
    const hashedPassword = await bcrypt.hash(password, 10);

    // Tạo user mới
    const newUser = new User({
      name,
      email,
      password: hashedPassword,
      imageUrl,
      phone,
      role: assignedRole
    });

    await newUser.save();

    res.status(201).json({
      message: `Đăng ký thành công với vai trò ${assignedRole}`,
      role: assignedRole
    });
  } catch (err) {
    console.error('❌ Lỗi trong POST /register:', err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});



// 📌 Đăng nhập
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // ✅ Kiểm tra đầu vào
    if (!email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'Tài khoản không tồn tại' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Mật khẩu không đúng' });

    // ✅ Tạo JWT token
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || 'secret_key',
      { expiresIn: '1h' }
    );

    // ✅ Ẩn mật khẩu khi trả về
    const { password: _, ...userWithoutPassword } = user.toObject();

    res.json({
      message: 'Đăng nhập thành công',
      token,
      user: userWithoutPassword
    });
  } catch (err) {
    console.error('❌ Lỗi login:', err);
    res.status(500).json({ message: 'Lỗi server. Vui lòng thử lại.' });
  }
}); 

// ✅ Cập nhật thông tin người dùng (name, email, phone, ảnh)
router.put('/:id', upload.single('image'), async (req, res) => {
  try {
    const userId = req.params.id;
    const { name, email, phone, currentPassword, newPassword } = req.body;
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : null;

    // Tìm user hiện tại
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }

    // Cập nhật các trường thông thường
    if (name) user.name = name;
    if (email) user.email = email;
    if (phone) user.phone = phone;
    if (imageUrl) user.imageUrl = imageUrl;

    // 🔐 Nếu có yêu cầu đổi mật khẩu
    if (currentPassword && newPassword) {
      const isMatch = await bcrypt.compare(currentPassword, user.password);
      if (!isMatch) {
        return res.status(400).json({ message: 'Mật khẩu hiện tại không đúng' });
      }

      const hashedNewPassword = await bcrypt.hash(newPassword, 10);
      user.password = hashedNewPassword;
    }

    const updatedUser = await user.save();

    // Ẩn mật khẩu
    const { password: _, ...userWithoutPassword } = updatedUser.toObject();

    res.json({
      message: 'Cập nhật thông tin thành công',
      user: userWithoutPassword,
    });
  } catch (err) {
    console.error('❌ Lỗi PUT /auth/:id:', err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

router.post('/send-otp', async (req, res) => {
  const { email } = req.body;

  try {
    const user = await User.findOne({ email });

    if (!user) {
      console.log(`❌ Không tìm thấy người dùng với email: ${email}`);
      return res.status(404).json({ message: 'Người dùng không tồn tại' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000; // 10 phút

    // Log chi tiết trước khi lưu
    console.log(`📧 Gửi OTP cho user: ${email}`);
    console.log(`🔑 Mã OTP tạo ra: ${otp}`);
    console.log(`⏳ OTP hết hạn lúc: ${new Date(expiresAt).toISOString()}`);

    // Gán và lưu vào DB
    user.otp = otp;
    user.otpExpires = new Date(expiresAt);
    await user.save();

    console.log(`✅ Đã lưu OTP vào DB cho email ${email}`);
    console.log(`📦 OTP lưu trong DB: ${user.otp}`);
    console.log(`⏰ Hết hạn OTP (DB): ${user.otpExpires}`);

    await sendEmail(email, otp);

    res.json({ message: 'OTP đã được gửi' });
  } catch (err) {
    console.error(`💥 Lỗi khi gửi OTP:`, err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});




// Đặt lại mật khẩu sau khi xác minh OTP
router.post('/reset-password', async (req, res) => {
  const { email, otp, newPassword } = req.body;
  console.log('📥 Yêu cầu đặt lại mật khẩu:', { email, otp, newPassword });

  try {
    const otpRecord = await Otp.findOne({ email, code: otp });
    console.log('🔍 OTP tìm được trong DB:', otpRecord);

    if (!otpRecord) {
      console.log('❌ Không tìm thấy mã OTP tương ứng trong DB');
      return res.status(400).json({ message: 'OTP không hợp lệ hoặc đã hết hạn' });
    }

    if (otpRecord.expiresAt < new Date()) {
      console.log(`⏰ OTP đã hết hạn lúc ${otpRecord.expiresAt}, hiện tại là ${new Date()}`);
      return res.status(400).json({ message: 'OTP không hợp lệ hoặc đã hết hạn' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      console.log('❌ Không tìm thấy người dùng với email:', email);
      return res.status(404).json({ message: 'Người dùng không tồn tại' });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();
    console.log('✅ Cập nhật mật khẩu thành công cho email:', email);

    await Otp.deleteMany({ email });
    console.log('🧹 Đã xoá tất cả OTP của email:', email);

    res.json({ message: '✅ Đặt lại mật khẩu thành công' });
  } catch (err) {
    console.error('❌ Lỗi server khi đặt lại mật khẩu:', err);
    res.status(500).json({ message: 'Lỗi server khi đặt lại mật khẩu' });
  }
});


// POST /api/auth/verify-otp

router.post('/verify-otp', async (req, res) => {
  const { email, otp } = req.body;

  try {
    const otpRecord = await Otp.findOne({ email, code: otp });
    if (!otpRecord || otpRecord.expiresAt < new Date()) {
      return res.status(400).json({ message: 'OTP không hợp lệ hoặc đã hết hạn' });
    }

    res.json({ message: '✅ OTP hợp lệ' }); // FE tự lưu OTP/email để gửi ở bước sau
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server khi xác minh OTP' });
  }
});




module.exports = router;
