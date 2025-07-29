const express = require('express');
const QRCode = require('qrcode');
const router = express.Router();

router.get('/', async (req, res) => {
  const { data } = req.query;

  if (!data) {
    return res.status(400).json({ error: 'Thiếu tham số data' });
  }

  try {
    const qrImage = await QRCode.toDataURL(data); // base64 image
    const img = Buffer.from(qrImage.split(",")[1], 'base64');
    res.writeHead(200, {
      'Content-Type': 'image/png',
      'Content-Length': img.length,
    });
    res.end(img);
  } catch (err) {
    res.status(500).json({ error: 'Không thể tạo mã QR' });
  }
});

module.exports = router;
