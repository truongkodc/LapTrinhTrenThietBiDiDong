# FITPLAN - ỨNG DỤNG LẬP KẾ HOẠCH & THEO DÕI TẬP LUYỆN THỂ DỤC

> **TRƯỜNG ĐẠI HỌC CÔNG NGHỆ TP.HCM (HUTECH)**  
> **KHOA CÔNG NGHỆ THÔNG TIN**  
> **Học phần:** Lập trình trên thiết bị di động (Mã học phần: **CMP177**)  
> **Đồ án môn học:** Xây dựng ứng dụng di động lập kế hoạch và theo dõi tập luyện cá nhân FitPlan

---

## 🎯 1. GIỚI THIỆU & MỤC TIÊU ỨNG DỤNG

**FitPlan** là ứng dụng di động hỗ trợ người dùng (đặc biệt là sinh viên) xây dựng lịch tập luyện theo từng ngày cụ thể, theo dõi tiến độ hoàn thành độc lập theo ngày, tham khảo kế hoạch tập mẫu theo mục tiêu và quản lý chỉ số cơ thể (BMI) ngay trên thiết bị.

Mục tiêu của đồ án:
- Tổ chức lịch tập linh hoạt theo **ngày cụ thể (một lần)** hoặc **lặp hằng tuần theo các thứ đã chọn**.
- Ghi nhận **trạng thái hoàn thành độc lập theo từng ngày** kèm **bản chụp (snapshot)** thông tin bài tập tại thời điểm hoàn thành, đảm bảo việc chỉnh sửa hoặc ngừng lịch về sau không làm sai lệch lịch sử những ngày trước.
- Hỗ trợ đa dạng đơn vị tính khối lượng bài tập (**lần**, **giây**, **phút**), kiểm tra dữ liệu nhập chặt chẽ và bảo toàn dữ liệu cục bộ an toàn qua hàng đợi ghi tuần tự.
- Cung cấp công cụ **Gợi ý kế hoạch tập luyện theo bộ quy tắc cố định** giúp người mới bắt đầu nhanh chóng tạo lịch tập tham khảo mà không cần kết nối mạng.

---

## 👥 2. THÔNG TIN NHÓM THỰC HIỆN

| Họ và tên | MSSV | GitHub | Công việc thực tế |
|---|---|---|---|
| Nguyễn Văn Sơn Trường | 2380164898 | truongkodc | Khởi tạo dự án và xây dựng phiên bản FitPlan ban đầu bằng Flutter: giao diện ba tab, đăng nhập cục bộ, quản lý và phân loại bài tập, xem chi tiết, đánh dấu hoàn thành và thống kê tiến độ, tính BMI, lưu dữ liệu bằng SharedPreferences và màn hình hồ sơ nhóm. |
| Châu Nhật Hữu | 2380600946 | huu2005 | Tiếp nhận và tổ chức lại mã nguồn; sửa lỗi; bổ sung lịch tập theo ngày và lịch sử hoàn thành, đơn vị bài tập, kiểm tra dữ liệu nhập, gợi ý kế hoạch theo quy tắc; hoàn thiện giao diện, hồ sơ và đăng xuất; kiểm thử, cập nhật README và quản lý các bản cập nhật trên Git. |
| Ngô Ngọc Ân | 2380600097 | ngo-ngoc-an | Soạn tài liệu mô tả các chức năng của FitPlan. |
| Trần Quang Việt | 2380602541 | MAPchai | Kiểm thử thủ công FitPlan trên máy ảo Android, ghi kết quả kiểm thử, chụp ảnh minh chứng và soạn kịch bản video demo. |
Nhóm gồm 4 thành viên. 

* **Giảng viên hướng dẫn / phụ trách:** Bùi Phú Khuyên
* **Kho lưu trữ mã nguồn (GitHub):** [https://github.com/truongkodc/LapTrinhTrenThietBiDiDong.git](https://github.com/truongkodc/LapTrinhTrenThietBiDiDong.git)

---

## 📱 3. CÁC CHỨC NĂNG ĐANG HOẠT ĐỘNG

| STT | Nhóm chức năng | Tên chức năng | Mô tả hoạt động thực tế |
|:---:|:---|:---|:---|
| 1 | **Phiên làm việc & Điều hướng đầu** | **Đăng nhập & Đăng xuất cục bộ** | Kiểm tra định dạng email và mật khẩu tối thiểu 6 ký tự (có nút hiện/ẩn mật khẩu). Lưu trạng thái phiên cục bộ; khi đăng xuất có hộp thoại xác nhận và chặn nút Back quay lại màn hình trong. |
| 2 | **Phiên làm việc & Điều hướng đầu** | **Màn hình chào sau đăng nhập** | Ngay sau khi đăng nhập, hiển thị màn hình chào với 3 lối tắt (*Xem kế hoạch hôm nay*, *Thêm bài tập mới*, *Cập nhật BMI*) và nút *Vào ứng dụng*. Khi mở lại app mà phiên còn hiệu lực thì vào thẳng màn hình chính. |
| 3 | **Kế hoạch tập theo ngày** | **Xem lịch tập theo từng ngày & phân nhóm** | Chuyển đổi ngày xem bằng nút ngày trước/ngày sau, chọn ngày trên lịch (`DatePicker`) hoặc quay nhanh về *Hôm nay*. Lọc bài tập trong ngày theo 4 tab: *Tất cả*, *Tăng cơ*, *Cardio*, *Thể lực*. |
| 4 | **Kế hoạch tập theo ngày** | **Thêm & Sửa bài tập (lịch 1 lần / lặp tuần)** | Tạo hoặc cập nhật bài tập với 2 kiểu lịch: *Tập một lần vào ngày cụ thể* hoặc *Lặp hằng tuần theo các thứ (`T2..CN`)* có ngày bắt đầu. Khi sửa bài tập, lịch mới có hiệu lực từ hôm nay và bảo toàn lịch sử các giai đoạn trước. |
| 5 | **Kế hoạch tập theo ngày** | **Đơn vị bài tập (`lần`, `giây`, `phút`)** | Hỗ trợ chọn đơn vị `lần`, `giây` hoặc `phút`. Nhãn ô nhập tự động đổi theo đơn vị (*Số lần/giây/phút mỗi hiệp*) và hiển thị thống nhất dạng `<số hiệp> hiệp × <số lượng> <đơn vị>` ở mọi màn hình. |
| 6 | **Kế hoạch tập theo ngày** | **Ngừng lịch tập & Hoàn tác (Undo)** | Ngừng bài tập khỏi lịch từ hôm nay trở đi sau khi xác nhận trên hộp thoại, giữ nguyên kết quả đã hoàn thành trong quá khứ/hôm nay và cho phép **Hoàn tác (Undo)** qua `SnackBar`. |
| 7 | **Theo dõi hoàn thành** | **Đánh dấu hoàn thành độc lập theo ngày & Snapshot** | Hoàn thành bài tập chỉ áp dụng cho ngày đang chọn (chặn đánh dấu cho ngày tương lai). Lưu bản chụp (`WorkoutCompletion` snapshot) gồm tên, nhóm, số hiệp, số lượng, đơn vị, kcal tại thời điểm hoàn thành. |
| 8 | **Chi tiết bài tập** | **Màn hình chi tiết bài tập** | Xem đầy đủ thông tin lịch tập, khối lượng, kcal ước tính, ghi chú kỹ thuật và bật/tắt trạng thái hoàn thành của ngày đang chọn. |
| 9 | **Gợi ý kế hoạch** | **Gợi ý kế hoạch theo bộ quy tắc cố định** | Chọn 1 trong 3 mục tiêu (*Tăng cơ*, *Cardio*, *Vận động tổng hợp*) và các thứ tập trong tuần (`T2..CN`), xem trước 3 bài tập mẫu cố định, bỏ chọn bài không muốn và thêm theo lô vào kế hoạch (tự động bỏ qua bài mẫu trùng lịch đang hoạt động). |
| 10 | **Thống kê & BMI** | **Thống kê ngày & Tính chỉ số BMI** | Hiển thị tỷ lệ hoàn thành, tổng kcal ước tính và danh sách bài đã hoàn thành của ngày đang chọn. Tính BMI từ cân nặng (`10–300 kg`) và chiều cao (`50–250 cm`), hỗ trợ dấu chấm/dấu phẩy thập phân và phân loại thể trạng. |
| 11 | **Cá nhân** | **Hồ sơ cục bộ & Hướng dẫn sử dụng** | Đặt/chỉnh sửa tên hiển thị (`1–50` ký tự, mặc định *“Người dùng FitPlan”*), xem thẻ tóm tắt *Chỉ số cơ thể* đồng bộ với tab BMI, mở bảng *Hướng dẫn sử dụng* và xem thông tin *Về ứng dụng*. |
| 12 | **An toàn dữ liệu** | **Chuyển đổi dữ liệu cũ & Bảo vệ khi lỗi lưu trữ** | Tự động chuyển đổi dữ liệu `exercises_v2` sang Store v3 (`fitplan_store_v3`) kèm bản sao lưu `exercises_v2_backup`. Nếu dữ liệu lưu trữ bị hỏng, hiển thị màn hình cảnh báo và khóa ghi đè để bảo vệ dữ liệu gốc. |

---

## 🛠️ 4. CÔNG NGHỆ SỬ DỤNG TRONG LUỒNG CHẠY THỰC TẾ

### 4.1. Công nghệ & thư viện đang hoạt động trong luồng chạy chính

| Thành phần | Công nghệ / Thư viện | Phiên bản (`pubspec.yaml`) | Vai trò thực tế trong ứng dụng |
|:---|:---|:---:|:---|
| **Framework & Ngôn ngữ** | Flutter / Dart | Dart SDK `^3.13.7` | Xây dựng toàn bộ giao diện, logic nghiệp vụ và kiểm thử tự động |
| **Giao diện (UI)** | Material Design 3 (`AppTheme`) | Built-in | Thiết kế giao diện thống nhất (bảng màu Teal `#00796B`, Amber `#F4B544`, nền `#EAF3F2`) |
| **Quản lý trạng thái** | `provider` | `^6.1.5+1` | Quản lý trạng thái tập trung qua `WorkoutProvider` (`ChangeNotifier`, `Consumer`) |
| **Lưu trữ cục bộ** | `shared_preferences` | `^2.5.6` | Lưu trữ bền vững Store v3 JSON (`fitplan_store_v3`), phiên đăng nhập, tên hiển thị và chỉ số BMI |
| **Định dạng dữ liệu** | `dart:convert` (JSON) | Built-in | Tuần tự hóa `Exercise`, `SchedulePeriod`, `WorkoutCompletion` sang JSON cục bộ |

### 4.2. Ghi chú minh bạch về các dependency và file helper khác trong kho mã
Trong `pubspec.yaml` và thư mục `lib/helpers/` hiện có khai báo một số gói/file từ các bài thực hành môn học trước:
- `sqflite`, `path` và file `lib/helpers/database_helper.dart` (minh họa CRUD SQLite).
- `http` và file `lib/helpers/api_service.dart` (minh họa gọi REST API).
- `firebase_core`, `firebase_auth`, `intl`.

> **Lưu ý:** Luồng chạy chính hiện tại của ứng dụng FitPlan (`lib/main.dart` → `lib/app.dart` → `lib/providers/workout_provider.dart` → các màn hình trong `lib/screens/`) **chỉ sử dụng `provider` và `shared_preferences`**, **không** gọi Firebase Authentication, SQLite hay REST API mạng trong các chức năng đang hoạt động.

---

## ⚠️ 5. PHẠM VI & GIỚI HẠN HIỆN TẠI CỦA ỨNG DỤNG

1. **Đăng nhập là phiên cục bộ:** Màn hình đăng nhập chỉ kiểm tra hợp lệ định dạng email/mật khẩu ở phía ứng dụng và lưu trạng thái phiên vào `SharedPreferences`, **chưa xác thực tài khoản trực tuyến** với máy chủ.
2. **Dữ liệu dùng chung trên thiết bị:** Danh sách bài tập, lịch sử hoàn thành, tên hiển thị và chỉ số BMI được lưu cục bộ trên thiết bị, **chưa tách riêng dữ liệu theo từng tài khoản email** khi đăng xuất và đăng nhập bằng email khác.
3. **Gợi ý kế hoạch dựa trên bộ quy tắc cố định (Rule-based):** Tính năng *Gợi ý kế hoạch* lấy danh sách bài tập mẫu cố định theo mục tiêu (*Tăng cơ*, *Cardio*, *Vận động tổng hợp*) và các thứ người dùng chọn, **không sử dụng AI**, không gọi mạng và không cá nhân hóa theo BMI, thiết bị tập hay tiền sử sức khỏe.
4. **Giá trị kcal mang tính ước tính minh họa:** Số `kcal` của mỗi bài tập (bao gồm cả bài mẫu) là giá trị ước tính cố định cho toàn bài tập trong ngày để phục vụ thống kê học tập, **không đo mức tiêu hao năng lượng sinh học thực tế** và không tự động thay đổi khi đổi đơn vị (`lần` / `giây` / `phút`).

---

## 📂 6. CẤU TRÚC THƯ MỤC MÃ NGUỒN CHÍNH

```text
LapTrinhTrenThietBiDiDong/
├── android/                                     # Cấu hình biên dịch Android (Gradle Kotlin DSL, Java/JVM 17)
├── lib/
│   ├── helpers/
│   │   ├── date_utils_helper.dart               # Xử lý khóa ngày địa phương (yyyy-MM-dd) và nhãn thứ tiếng Việt
│   │   ├── plan_suggestion_helper.dart          # Bộ quy tắc cố định và danh mục 9 bài tập mẫu cho 3 mục tiêu
│   │   ├── api_service.dart                     # File helper bài thực hành REST API (không dùng trong luồng chính)
│   │   └── database_helper.dart                 # File helper bài thực hành SQLite (không dùng trong luồng chính)
│   ├── models/
│   │   ├── exercise.dart                        # Model Exercise, SchedulePeriod, ExerciseUnits & migration dữ liệu cũ
│   │   ├── day_workout_item.dart                # Model kết hợp bài tập và trạng thái hoàn thành của ngày đang xem
│   │   └── workout_completion.dart              # Model bản ghi hoàn thành theo ngày kèm snapshot thông tin bài tập
│   ├── providers/
│   │   └── workout_provider.dart                # Quản lý trạng thái chính, Store v3 JSON và hàng đợi lưu tuần tự
│   ├── screens/
│   │   ├── login_screen.dart                    # Màn hình đăng nhập phiên cục bộ
│   │   ├── welcome_choice_screen.dart           # Màn hình chào và chọn lối tắt sau đăng nhập
│   │   ├── dashboard_screen.dart                # Khung điều hướng BottomNavigationBar 3 tab chính
│   │   ├── workout_plan_tab.dart                # Tab Kế hoạch tập theo ngày, thêm/sửa/ngừng lịch bài tập
│   │   ├── plan_suggestion_screen.dart          # Màn hình Gợi ý kế hoạch tập mẫu theo quy tắc cố định
│   │   ├── exercise_detail_screen.dart          # Màn hình xem chi tiết bài tập và đánh dấu hoàn thành
│   │   ├── bmi_and_stats_tab.dart               # Tab Thống kê ngày, lịch sử hoàn thành và tính BMI
│   │   └── profile_tab.dart                     # Tab Cá nhân (tên hiển thị, chỉ số cơ thể, hướng dẫn, đăng xuất)
│   ├── app.dart                                 # Widget gốc FitPlanApp và điều hướng theo trạng thái phiên
│   ├── app_theme.dart                           # Cấu hình bảng màu và Material 3 ThemeData
│   └── main.dart                                # Điểm khởi chạy ứng dụng và khởi tạo ChangeNotifierProvider
├── test/
│   ├── workout_schedule_and_migration_test.dart # Unit test lịch theo ngày, migration, hàng đợi lưu, đơn vị & BMI
│   └── widget_test.dart                         # Widget & unit test các màn hình, luồng người dùng và gợi ý kế hoạch
├── pubspec.yaml                                 # Khai báo cấu hình gói và dependencies của dự án
└── README.md                                    # Tài liệu hướng dẫn và thuyết minh dự án
```

---

## 🚀 7. HƯỚNG DẪN CÀI ĐẶT, CHẠY & KIỂM TRA DỰ ÁN

### 7.1. Yêu cầu môi trường
- **Flutter SDK** hỗ trợ **Dart SDK `^3.13.7`** (khuyến nghị Flutter 3.x mới nhất).
- **JDK 17** (cấu hình Android Gradle tại `android/app/build.gradle.kts` sử dụng `JavaVersion.VERSION_17` và Kotlin `JVM_17`).
- **Android SDK** kèm máy ảo Android (Android Emulator) hoặc thiết bị Android thật đã bật **USB Debugging**.

### 7.2. Cài đặt dependency
Clone kho mã nguồn và tải các gói thư viện:
```bash
git clone https://github.com/truongkodc/LapTrinhTrenThietBiDiDong.git
cd LapTrinhTrenThietBiDiDong
flutter pub get
```

### 7.3. Chạy ứng dụng trên Android
Khởi động máy ảo Android hoặc kết nối thiết bị thật, sau đó chạy:
```bash
flutter run
```

### 7.4. Kiểm tra mã nguồn tĩnh (Static Analysis)
```bash
flutter analyze
```

### 7.5. Chạy bộ kiểm thử tự động (Unit & Widget Tests)
```bash
flutter test
```

### 7.6. Đóng gói file cài đặt APK bản Debug
```bash
flutter build apk --debug
```
Sau khi lệnh hoàn tất, file APK đầu ra nằm tại:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 📄 8. THÔNG TIN HỌC PHẦN & LIÊN KẾT REPOSITORY

- **Đồ án môn học:** Lập trình trên thiết bị di động (**CMP177**) – Khoa Công nghệ Thông tin, Trường Đại học Công nghệ TP.HCM (**HUTECH**).
- **GitHub Repository (`origin`):** [https://github.com/truongkodc/LapTrinhTrenThietBiDiDong.git](https://github.com/truongkodc/LapTrinhTrenThietBiDiDong.git)
