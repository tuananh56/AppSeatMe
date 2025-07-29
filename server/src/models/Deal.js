const mongoose = require('mongoose');

const dealSchema = new mongoose.Schema({
  image: String,
  title: String,
  expiry: String,
});

module.exports = mongoose.model('Deal', dealSchema);
