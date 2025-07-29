const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema({
  userEmail: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
}, {
  timestamps: true // để có createdAt, updatedAt
});

module.exports = mongoose.model("Notification", notificationSchema);
