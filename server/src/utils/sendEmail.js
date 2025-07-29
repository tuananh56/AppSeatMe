const nodemailer = require('nodemailer');
const Otp = require('../models/Otp'); // Import model Otp
require('dotenv').config();

const sendEmail = async (to) => {
  // 🔐 Kiểm tra xem đã có mã OTP cho email này chưa
  const existingOtp = await Otp.findOne({ email: to });

  if (existingOtp) {
    console.log(`✅ Đã tồn tại OTP cho email ${to}. Không gửi lại.`);
    return; // Không gửi lại OTP nếu đã tồn tại
  }

  // 🔐 Tạo mã OTP và thời gian hết hạn
  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 phút

  // 📧 Cấu hình transporter Gmail
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  // ✉️ Soạn nội dung email
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to,
    subject: 'Yêu cầu đặt lại mật khẩu - Mã OTP của bạn',
    text: `Xin chào,

Bạn đã yêu cầu đặt lại mật khẩu cho tài khoản của mình.

Mã OTP của bạn là: ${otpCode}
(Lưu ý: Mã OTP này sẽ hết hạn sau 10 phút)

Vui lòng sử dụng mã này để xác minh và tiếp tục quá trình đổi mật khẩu.

Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.

Trân trọng,
Đội ngũ hỗ trợ`,
  };

  // 📤 Gửi email
  await transporter.sendMail(mailOptions);

  // 💾 Lưu OTP mới vào DB
  const newOtp = new Otp({ email: to, code: otpCode, expiresAt });
  await newOtp.save();

  // 🪵 Log kiểm tra
  console.log(`📧 Gửi OTP cho user: ${to}`);
  console.log(`🔑 Mã OTP tạo ra: ${otpCode}`);
  console.log(`⏳ OTP hết hạn lúc: ${expiresAt}`);
  console.log(`✅ Đã lưu OTP vào DB cho email ${to}`);
};

module.exports = sendEmail;
