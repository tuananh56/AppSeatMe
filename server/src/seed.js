const mongoose = require('mongoose');
const Branch = require('./models/Branch');

mongoose.connect('mongodb://localhost:27017/app_dat_ban')
  .then(async () => {
    console.log("✅ Kết nối MongoDB thành công");

    // Danh sách chi nhánh kèm theo tọa độ (kinh độ, vĩ độ)
    const branches = [
      {
        name: 'Chi nhánh 1',
        address: 'Số 11 Nguyễn Văn Quá, P. Đông Hưng Thuận, Q.12',
        image: 'chinhanh1.jpg',
        location: {
          type: 'Point',
          coordinates: [106.6227, 10.8437] // [lng, lat]
        }
      },
      {
        name: 'Chi nhánh 2',
        address: 'Số 23 Chế Lan Viên, P. Tây Thạnh, Q. Tân Phú',
        image: 'chinhanh2.jpg',
        location: {
          type: 'Point',
          coordinates: [106.6203, 10.8035]
        }
      },
      {
        name: 'Chi nhánh 3',
        address: 'Số 62 Hoàng Văn Thụ, Q.3',
        image: 'chinhanh3.png',
        location: {
          type: 'Point',
          coordinates: [106.6825, 10.7976]
        }
      },
      {
        name: 'Chi nhánh 4',
        address: 'Số 38 Lý Tự Trọng, Q.10',
        image: 'chinhanh4.png',
        location: {
          type: 'Point',
          coordinates: [106.6883, 10.7772]
        }
      },
      {
        name: 'Chi nhánh 5',
        address: 'Số 42 Quang Trung, Q.Tân Phú',
        image: 'chinhanh5.png',
        location: {
          type: 'Point',
          coordinates: [106.6652, 10.8261]
        }
      },
        {
        name: 'Chi nhánh Hóc Môn',
        address: 'Số 806 Quốc lộ 22 (quốc lộ 22 cũ), Ấp Mỹ Hòa 3, Xã Tân Xuân, Huyện Hóc Môn, TP. HCM ',
        image: 'HFHC.webp',
        location: {
          type: 'Point',
          coordinates: [106.59250, 10.87833] // [lng, lat]
        }
      },
    ];

    // Xóa cũ và thêm mới
    await Branch.deleteMany({});
    await Branch.insertMany(branches);

    console.log('✅ Đã thêm dữ liệu chi nhánh có tọa độ');
    process.exit();
  })
  .catch(err => console.error("❌ Lỗi kết nối:", err));
