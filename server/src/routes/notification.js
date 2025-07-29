const express = require("express");
const router = express.Router();
const Notification = require("../models/Notification");

// 📌 Tạo thông báo mới
router.post("/", async (req, res) => {
  try {
    const { userEmail, message } = req.body;

    const newNotification = new Notification({ userEmail, message });
    await newNotification.save();

    res.status(201).json({ message: "Tạo thông báo thành công", data: newNotification });
  } catch (error) {
    console.error("❌ Lỗi tạo thông báo:", error);
    res.status(500).json({ message: "Lỗi server" });
  }
});

// 📌 Lấy thông báo theo email
router.get("/:userEmail", async (req, res) => {
  try {
    const { userEmail } = req.params;
    const notifications = await Notification.find({ userEmail }).sort({ createdAt: -1 });
    res.status(200).json(notifications);
  } catch (error) {
    console.error("❌ Lỗi fetch thông báo:", error);
    res.status(500).json({ message: "Lỗi tải thông báo" });
  }
});


module.exports = router;
