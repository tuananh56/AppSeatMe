const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  imageUrl: { type: String, required: true },
  phone: { type: String, required: true },
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  favoriteBranches: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Branch' }],

  // ✅ Thêm vào đây
  otp: { type: String },
  otpExpires: { type: Date }
});

module.exports = mongoose.model('User', userSchema);
