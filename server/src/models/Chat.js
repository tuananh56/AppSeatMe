const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  senderId: { type: String, required: true },      // ID người gửi (userId hoặc adminId)
  receiverId: { type: String, required: true },    // ID người nhận
  message: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

// Tự động tạo chỉ mục để tìm kiếm chat nhanh hơn
chatSchema.index({ senderId: 1, receiverId: 1, createdAt: 1 });

module.exports = mongoose.model('Chat', chatSchema);
