const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();
const Booking = require('../models/Booking');

// 📌 Tạo đơn đặt bàn mới
router.post('/', async (req, res) => {
  console.log('📥 Dữ liệu nhận được:', req.body);

  try {
    const {
      name, email, phone, soGhe,
      date, time, note,
      chiNhanh, diaChi, userId
    } = req.body;

    // Kiểm tra dữ liệu đầu vào
    if (!name || !phone || !soGhe || !date || !time || !userId) {
      return res.status(400).json({ message: 'Vui lòng điền đủ thông tin bắt buộc' });
    }

    const phoneRegex = /^[0-9]{9,11}$/;
    if (!phoneRegex.test(phone)) {
      return res.status(400).json({ message: 'Số điện thoại không hợp lệ' });
    }

    if (isNaN(soGhe) || soGhe <= 0) {
      return res.status(400).json({ message: 'Số ghế phải là số dương' });
    }

    const tienCoc = soGhe * 50000;

    const newBooking = new Booking({
      name,
      email,
      phone,
      soGhe,
      date: new Date(date),
      time,
      note,
      chiNhanh,
      diaChi,
      tienCoc,
      trangThaiThanhToan: 'Chưa thanh toán',
      trangThaiXacNhan: 'Chờ xác nhận',
      userId
    });

    await newBooking.save();

    res.status(201).json({
      message: 'Đặt bàn thành công',
      booking: newBooking
    });

  } catch (err) {
    console.error('❌ Lỗi đặt bàn:', err);
    res.status(500).json({ message: 'Lỗi server khi đặt bàn' });
  }
});

// 📌 Cập nhật trạng thái thanh toán
router.post('/:id/pay', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'ID không hợp lệ' });
    }

    const booking = await Booking.findById(id);
    if (!booking) {
      return res.status(404).json({ message: 'Không tìm thấy đơn đặt bàn' });
    }

    booking.trangThaiThanhToan = 'Đã thanh toán';
    await booking.save();

    res.json({
      message: 'Cập nhật thanh toán thành công',
      booking
    });

  } catch (err) {
    console.error('❌ Lỗi khi cập nhật thanh toán:', err);
    res.status(500).json({ message: 'Lỗi server khi cập nhật thanh toán' });
  }
});

// 📌 GET tất cả đơn hàng ĐÃ THANH TOÁN (cho AdminPage)
router.get('/', async (req, res) => {
  try {
    const bookings = await Booking.find().sort({ createdAt: -1 }); // KHÔNG lọc theo trạng thái thanh toán
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi khi lấy danh sách đơn hàng' });
  }
});

// 📌 Route riêng lấy đơn hàng đã thanh toán (nếu cần gọi khác endpoint)
router.get('/orders/paid', async (req, res) => {
  try {
    const paidOrders = await Booking.find({ trangThaiThanhToan: 'Đã thanh toán' });
    res.json(paidOrders);
  } catch (err) {
    console.error('❌ Lỗi khi lấy đơn hàng đã thanh toán:', err);
    res.status(500).send('Lỗi server');
  }
});

// 📌 Xác nhận đơn đặt bàn
router.post('/:id/confirm', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Không tìm thấy đơn' });

    booking.trangThaiXacNhan = 'Đã xác nhận';
    await booking.save();

    res.json({ message: 'Đã xác nhận đơn hàng', booking });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server khi xác nhận đơn' });
  }
});

// 📌 Hủy đơn đặt bàn
router.put('/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'ID không hợp lệ' });
    }

    const result = await Booking.findByIdAndUpdate(
      id,
      { trangThaiXacNhan: 'Đã hủy' },
      { new: true }
    );

    if (!result) {
      return res.status(404).json({ message: 'Không tìm thấy đơn hàng' });
    }

    res.json({ message: 'Đã hủy đơn hàng', booking: result });
  } catch (err) {
    console.error('❌ Lỗi khi hủy đơn:', err);
    res.status(500).json({ message: 'Lỗi server khi hủy đơn hàng' });
  }
});

// 📌 Lấy lịch sử đặt bàn của một user
router.get('/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const bookings = await Booking.find({ userId }).sort({ createdAt: -1 });

    res.json(bookings);
  } catch (err) {
    console.error('❌ Lỗi khi lấy lịch sử đặt bàn:', err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

module.exports = router;
