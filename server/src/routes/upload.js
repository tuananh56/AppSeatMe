const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

// 🔰 Dùng đúng đường dẫn thư mục uploads
const uploadDir = path.join(__dirname, '../uploads'); // server/src/uploads

// Tạo thư mục nếu chưa có
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Cấu hình multer
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir); // ⬅️ Lưu file vào src/uploads
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({ storage });

router.post('/', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'Không có file nào được upload.' });
  }

  const imageUrl = `/uploads/${req.file.filename}`; // Trả về URL cho client
  res.status(200).json({ message: 'Upload thành công', url: imageUrl });
});

module.exports = router;
