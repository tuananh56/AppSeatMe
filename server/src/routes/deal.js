const express = require('express');
const router = express.Router();
const Deal = require('../models/Deal');

// 📌 Lấy danh sách tất cả ưu đãi
router.get('/', async (req, res) => {
  try {
    const deals = await Deal.find(); // lấy hết hoặc thêm sort/limit nếu cần TOP
    res.json(deals);
  } catch (err) {
    console.error('❌ Lỗi khi lấy danh sách ưu đãi:', err);
    res.status(500).json({ message: 'Lỗi server khi lấy ưu đãi' });
  }
});

module.exports = router;
