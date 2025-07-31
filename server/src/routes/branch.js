const express = require('express');
const router = express.Router();
const Branch = require('../models/Branch');

// ✅ Route 1: Lấy tất cả chi nhánh
router.get('/', async (req, res) => {
  try {
    const branches = await Branch.find();
    res.json(branches);
  } catch (err) {
    console.error('❌ Lỗi lấy danh sách chi nhánh:', err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// ✅ Route 2: Tìm kiếm theo tên hoặc địa chỉ
router.get('/search', async (req, res) => {
  const query = req.query.query || '';
  try {
    const results = await Branch.find({
      $or: [
        { name: { $regex: query, $options: 'i' } },
        { address: { $regex: query, $options: 'i' } }
      ]
    });
    res.json(results);
  } catch (err) {
    console.error('❌ Lỗi khi tìm kiếm chi nhánh:', err);
    res.status(500).json({ message: 'Lỗi server khi tìm kiếm' });
  }
});

// ✅ Route 3: Tìm chi nhánh gần vị trí người dùng
router.get('/nearby', async (req, res) => {
  const { lat, lng } = req.query;

  if (!lat || !lng) {
    return res.status(400).json({ message: 'Thiếu tham số lat hoặc lng' });
  }

  try {
    const userLocation = {
      type: 'Point',
      coordinates: [parseFloat(lng), parseFloat(lat)], // Lưu ý: MongoDB dùng [longitude, latitude]
    };

    const branches = await Branch.find({
      location: {
        $near: {
          $geometry: userLocation,
          $maxDistance: 20000, // 5km
        },             
      },
    });

    res.json(branches);
  } catch (err) {
    console.error('❌ Lỗi tìm chi nhánh gần bạn:', err);
    res.status(500).json({ message: 'Lỗi server khi tìm gần vị trí' });
  }
});

module.exports = router;
