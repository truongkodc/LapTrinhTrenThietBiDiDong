# FITPLAN - ỨNG DỤNG LẬP KẾ HOẠCH & THEO DÕI TẬP LUYỆN THỂ DỤC

> **TRƯỜNG ĐẠI HỌC CÔNG NGHỆ TP.HCM (HUTECH)**  
> **KHOA CÔNG NGHỆ THÔNG TIN**  
> **Học phần:** Lập trình trên thiết bị di động (Mã học phần: **CMP177**)  
> **Đồ án cuối kỳ:** Xây dựng ứng dụng di động theo dõi và lập kế hoạch tập luyện FitPlan

---

## 👥 1. THÔNG TIN NHÓM THỰC HIỆN

| STT | Họ và Tên | Mã số sinh viên (MSSV) | Lớp | Vai trò / Nhiệm vụ |
|:---:|:---|:---:|:---:|:---|
| 1 | [Điền Họ và Tên Thành Viên 1] | [Điền MSSV 1] | [Điền Lớp] | Trưởng nhóm / Phát triển chức năng chính |
| 2 | [Điền Họ và Tên Thành Viên 2] | [Điền MSSV 2] | [Điền Lớp] | Thiết kế giao diện & CSDL |
| 3 | [Điền Họ và Tên Thành Viên 3] | [Điền MSSV 3] | [Điền Lớp] | Kiểm thử & Tích hợp API |

* **Giảng viên hướng dẫn / phụ trách:** [Điền Tên Giảng Viên Phụ Trách]
* **Học kỳ – Năm học:** Học kỳ 1 – Năm học 2026-2027

---

## 🛠️ 2. TỔNG QUAN CÔNG NGHỆ & THƯ VIỆN SỬ DỤNG

Bảng tóm tắt các công nghệ và thư viện cốt lõi được áp dụng trong đồ án:

| Thành phần | Công nghệ / Thư viện | Phiên bản | Mục đích sử dụng |
|:---|:---|:---:|:---|
| **Mobile App Framework** | Flutter / Dart | Flutter 3.x / Dart 3.x | Xây dựng giao diện đa nền tảng cho ứng dụng di động |
| **State Management** | `provider` | ^6.1.5 | Quản lý trạng thái tập trung (ChangeNotifier, Consumer) |
| **Local Database** | `sqflite` & `path` | ^2.4.2 / ^1.9.1 | Cơ sở dữ liệu SQLite cục bộ lưu trữ kế hoạch bài tập |
| **Local Storage** | `shared_preferences` | ^2.5.6 | Lưu trữ cấu hình ứng dụng, phiên đăng nhập, chỉ số thể chất |
| **HTTP Networking** | `http` | ^1.4.0 | Giao tiếp mạng REST API (GET gợi ý bài tập, POST dữ liệu) |
| **Data Format** | JSON Serialization | Built-in | Chuyển đổi dữ liệu đối tượng `Exercise` ↔ `Map<String, dynamic>` |
| **UI Components** | Material Design 3 | Built-in | Giao diện hiện đại, TabBar, BottomNavigationBar, Dialog, SnackBar |

---

## 📱 3. TỔNG HỢP DANH SÁCH CHỨC NĂNG

| STT | Module | Tên chức năng | Mô tả tóm tắt | Trạng thái |
|:---:|:---|:---|:---|:---:|
| 1 | **Tài khoản** | Đăng nhập hệ thống | Kiểm tra định dạng email sinh viên, mật khẩu tối thiểu 6 ký tự | **Hoàn thành** |
| 2 | **Tài khoản** | Đăng xuất | Xóa phiên làm việc và trở lại màn hình đăng nhập | **Hoàn thành** |
| 3 | **Kế hoạch tập** | Xem danh sách bài tập | Hiển thị bài tập theo dạng thẻ Card, lọc theo tab (Tất cả, Tăng cơ, Cardio, Thể lực) | **Hoàn thành** |
| 4 | **Kế hoạch tập** | Thêm bài tập mới | Nhập thông tin (tên, nhóm bài, số hiệp/lần, calo, lịch tập) với form validation | **Hoàn thành** |
| 5 | **Kế hoạch tập** | Cập nhật bài tập | Cho phép chỉnh sửa thông tin bài tập đã lưu | **Hoàn thành** |
| 6 | **Kế hoạch tập** | Xóa bài tập & Hoàn tác | Hiển thị hộp thoại xác nhận xóa, hỗ trợ nút "Hoàn tác (Undo)" qua SnackBar | **Hoàn thành** |
| 7 | **Kế hoạch tập** | Đánh dấu hoàn thành | Checkbox cập nhật tiến độ tập luyện và tính năng lượng tiêu hao tức thì | **Hoàn thành** |
| 8 | **Chi tiết bài tập** | Màn hình chi tiết | Điều hướng Navigator chuyển sang màn hình hướng dẫn kỹ thuật tập | **Hoàn thành** |
| 9 | **Thống kê & BMI** | Tính chỉ số BMI | Nhập chiều cao/cân nặng, tính BMI tự động kèm đánh giá thể trạng | **Hoàn thành** |
| 10 | **Thống kê & BMI** | Thanh tiến độ trực quan | LinearProgressIndicator thể hiện tỉ lệ phần trăm hoàn thành trong ngày | **Hoàn thành** |
| 11 | **Kết nối API** | Gợi ý bài tập từ REST API | Kết nối REST API lấy danh sách bài tập gợi ý từ internet qua FutureBuilder | **Hoàn thành** |
| 12 | **Hồ sơ nhóm** | Thông tin đồ án & SV | Màn hình thông tin học phần, nhóm tác giả và kiến trúc ứng dụng | **Hoàn thành** |

---

## 📂 4. CẤU TRÚC THƯ MỤC MÃ NGUỒN

```text
fitplan_hutech/
├── android/                 # Cấu hình dự án cho nền tảng Android
├── assets/
│   └── images/              # Thư mục hình ảnh minh họa bài tập và logo
├── lib/
│   ├── helpers/             # Các lớp tiện ích, kết nối CSDL và mạng
│   │   ├── api_service.dart     # Giao tiếp REST API HTTP
│   │   └── database_helper.dart # SQLite database CRUD
│   ├── models/              # Định nghĩa cấu trúc dữ liệu
│   │   └── exercise.dart        # Model Exercise kèm JSON & Map serialization
│   ├── providers/           # Quản lý trạng thái ứng dụng (State Management)
│   ├── screens/             # Màn hình giao diện người dùng
│   ├── widgets/             # Các thành phần giao diện tái sử dụng
│   ├── app_theme.dart       # Cấu hình màu sắc, theme Material 3
│   └── main.dart            # Điểm khởi chạy ứng dụng (Entry point)
├── pubspec.yaml             # Khai báo thư viện và tài nguyên (assets)
└── README.md                # Tài liệu thuyết minh dự án
```

---

## 🚀 5. HƯỚNG DẪN CÀI ĐẶT & CHẠY ỨNG DỤNG

### Yêu cầu hệ thống:
* **Flutter SDK:** Phiên bản `>= 3.13.7`
* **Dart SDK:** Đi kèm theo Flutter
* Thiết bị giả lập (Android Emulator) hoặc thiết bị thật đã bật tính năng **USB Debugging**.

### Các bước thực hiện:

1. **Clone mã nguồn từ GitHub:**
   ```bash
   git clone https://github.com/truongkodc/LapTrinhTrenThietBiDiDong.git
   cd LapTrinhTrenThietBiDiDong
   ```

2. **Cài đặt các gói thư viện phụ thuộc:**
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng trên thiết bị / máy ảo:**
   ```bash
   flutter run
   ```

---

## 📄 6. THÔNG TIN BẢN QUYỀN & MÔN HỌC

* Đồ án được xây dựng phục vụ đánh giá kết quả học tập môn **Lập trình trên thiết bị di động (CMP177)** tại **Đại học Công nghệ TP.HCM (HUTECH)**.
* Mã nguồn được phát hành công khai tại GitHub: [https://github.com/truongkodc/LapTrinhTrenThietBiDiDong](https://github.com/truongkodc/LapTrinhTrenThietBiDiDong)
