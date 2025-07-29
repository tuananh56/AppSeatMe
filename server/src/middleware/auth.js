const jwt = require('jsonwebtoken');

// Middleware xác thực người dùng
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Lấy phần sau "Bearer "

  if (!token) {
    return res.status(401).json({ message: 'Không có token' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret_key');
    req.user = decoded; // Gắn user info (như _id, email,...) vào request
    next(); // Cho phép đi tiếp
  } catch (err) {
    return res.status(403).json({ message: 'Token không hợp lệ' });
  }
};

module.exports = authMiddleware;
