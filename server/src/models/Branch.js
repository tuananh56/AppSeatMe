const mongoose = require('mongoose');

const branchSchema = new mongoose.Schema({
  name: String,
  address: String,
  image: String, // ví dụ: 'chinhanh1.jpg'
  location: {
    type: {
      type: String,
      enum: ['Point'], // Phải là "Point"
      required: true,
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
    },
  },
});

// ✅ Tạo chỉ mục để MongoDB hỗ trợ tìm theo vị trí (2dsphere index)
branchSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Branch', branchSchema);
