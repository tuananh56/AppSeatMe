const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },                         // Tên KH
  email: { type: String, trim: true, lowercase: true },                       // Email
  phone: { type: String, required: true, trim: true },                        // SĐT
  soGhe: { type: Number, required: true, min: 1 },                            // Số ghế
  date: { type: Date, required: true },                                       // Ngày đặt
  time: { type: String, required: true },                                     // Giờ đặt (HH:mm)
  note: { type: String, trim: true },                                         // Ghi chú
  chiNhanh: { type: String, trim: true },                                     // Tên chi nhánh
  diaChi: { type: String, trim: true },                                       // Địa chỉ chi nhánh

  tienCoc: { type: Number, default: 0, min: 0 },                              // Tiền cọc (tự tính)

  trangThaiThanhToan: {
    type: String,
    enum: ['Chưa thanh toán', 'Đã thanh toán'],
    default: 'Chưa thanh toán',
  },

  trangThaiXacNhan: {
    type: String,
    enum: ['Chờ xác nhận', 'Đã xác nhận', 'Đã hủy'],
    default: 'Chờ xác nhận',
  },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdAt: { type: Date, default: Date.now }                                // Ngày tạo
});

// 👉 Tự động tạo chỉ mục theo ngày tạo để sắp xếp mới nhất trước
bookingSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Booking', bookingSchema);
