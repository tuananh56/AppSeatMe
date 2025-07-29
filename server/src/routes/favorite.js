const express = require('express');
const router = express.Router();
const Favorite = require('../models/favorite'); // dùng chữ thường

// ✅ [POST] Thêm chi nhánh vào danh sách yêu thích
router.post('/', async (req, res) => {
  const { userId, branchId } = req.body;

  if (!userId || !branchId) {
    return res.status(400).json({ message: 'Thiếu userId hoặc branchId' });
  }

  try {
    // Kiểm tra đã tồn tại hay chưa
    const existing = await Favorite.findOne({ userId, branchId });
    if (existing) {
      return res.status(400).json({ message: 'Chi nhánh đã có trong danh sách yêu thích' });
    }

    const favorite = new Favorite({ userId, branchId });
    await favorite.save();

    res.status(201).json({
      message: 'Đã thêm vào danh sách yêu thích',
      favorite,
    });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server khi thêm yêu thích', error: error.message });
  }
});

// ✅ [GET] Lấy danh sách yêu thích của một người dùng
router.get('/:userId', async (req, res) => {
  const userId = req.params.userId?.trim();

  if (!userId) {
    return res.status(400).json({ message: 'Thiếu userId' });
  }

  try {
    const favorites = await Favorite.find({ userId }).populate('branchId');

    // Trả về danh sách chi nhánh (branch) thay vì bản ghi Favorite
    const branchList = favorites
      .filter(fav => fav.branchId) // tránh lỗi nếu branch đã bị xoá
      .map(fav => ({
        _id: fav.branchId._id,
        name: fav.branchId.name,
        address: fav.branchId.address,
        image: fav.branchId.image,
      }));

    res.json(branchList);
  } catch (error) {
    res.status(500).json({
      message: 'Lỗi server khi lấy danh sách yêu thích',
      error: error.message,
    });
  }
});

// ✅ [DELETE] Xoá chi nhánh khỏi danh sách yêu thích
router.delete('/', async (req, res) => {
  const { userId, branchId } = req.body;

  if (!userId || !branchId) {
    return res.status(400).json({ message: 'Thiếu userId hoặc branchId' });
  }

  try {
    const deleted = await Favorite.findOneAndDelete({ userId, branchId });

    if (!deleted) {
      return res.status(404).json({ message: 'Không tìm thấy để xoá' });
    }

    res.json({ message: 'Đã xoá khỏi danh sách yêu thích' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server khi xoá yêu thích', error: error.message });
  }
});

// ✅ [GET] Kiểm tra 1 chi nhánh đã được yêu thích chưa
// Ví dụ: /api/favorites/check?userId=xxx&branchId=yyy
router.get('/check', async (req, res) => {
  const { userId, branchId } = req.query;

  if (!userId || !branchId) {
    return res.status(400).json({ message: 'Thiếu userId hoặc branchId' });
  }

  try {
    const exists = await Favorite.findOne({ userId, branchId });
    res.json({ exists: !!exists });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server khi kiểm tra yêu thích', error: error.message });
  }
});

module.exports = router;
