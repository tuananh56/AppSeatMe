const mongoose = require('mongoose');
const Deal = require('./models/Deal'); // Đảm bảo file models/Deal.js đã được tạo

// 1. Kết nối đến MongoDB
mongoose.connect('mongodb://localhost:27017/app_dat_ban', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
  .then(async () => {
    console.log('✅ Kết nối MongoDB thành công');

    // 2. Dữ liệu ưu đãi mẫu
    const deals = [
      {
        title: 'Combo ưu đãi 1',
        image: 'uudai1.jpg',
        expiry: '30/06/2025'
      },
      {
        title: 'Combo ưu đãi 2',
        image: 'uudai2.webp',
        expiry: '12/07/2025'
      },
      {
        title: 'Combo ưu đãi 3',
        image: 'uudai3.jpg',
        expiry: '29/09/2025'
      },
      {
        title: 'Combo ưu đãi 4',
        image: 'uudai4.jpg',
        expiry: '16/08/2025'
      },
      {
        title: 'Combo ưu đãi 5',
        image: 'uudai5.jpg',
        expiry: '14/07/2025'
      }
    ];

    // 3. Xóa tất cả ưu đãi cũ và thêm mới
    await Deal.deleteMany({});
    await Deal.insertMany(deals);

    console.log('✅ Đã thêm mới danh sách ưu đãi');
    process.exit(); // Thoát chương trình
  })
  .catch((err) => {
    console.error('❌ Lỗi kết nối MongoDB:', err);
    process.exit(1); // Thoát chương trình với mã lỗi
  });
