const mongoose = require('mongoose');

const FavoriteSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true },
});

module.exports = mongoose.model('Favorite', FavoriteSchema);
