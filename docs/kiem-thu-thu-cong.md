# Kiểm thử thủ công FitPlan

- Học phần: Lập trình trên thiết bị di động (CMP177), nhóm 7.
- Người thực hiện: Trần Quang Việt (MSSV 2380602541).
- Ngày kiểm thử: 11/11/2026.
- Thiết bị: Android Emulator, Medium Phone API 37.0, Android 17, x86_64.
- Phiên bản kiểm thử: commit `2fe9e03`, nhánh `docs/viet-kiem-thu-video`.
- Môi trường build: Windows, Flutter chạy ở chế độ debug. Đặt `kotlin.incremental=false` trong `android/gradle.properties` trên máy kiểm thử để xử lý lỗi cache Kotlin khi build.

## Kết quả kiểm thử

| Mã | Chức năng | Bước thực hiện | Kết quả mong đợi | Kết quả thực tế | Đạt/Chưa đạt |
|---|---|---|---|---|---|
| KT-01 | Mật khẩu trống | Giữ email mẫu, để trống mật khẩu và bấm Đăng nhập. | Báo lỗi và giữ màn hình đăng nhập. | App báo mật khẩu phải có ít nhất 6 ký tự, không chuyển màn hình. | Đạt |
| KT-02 | Đăng nhập cục bộ | Nhập email mẫu và mật khẩu thử có ít nhất 6 ký tự, rồi bấm Đăng nhập. | Mở màn hình chào và hiển thị email đã nhập. | Màn hình chào hiển thị `sv.hutech@edu.vn` và nút Vào ứng dụng. | Đạt |
| KT-03 | Lối tắt Kế hoạch hôm nay | Chọn Kế hoạch hôm nay trên màn hình chào. | Mở tab Kế hoạch tập với ngày hôm nay. | App chọn 11/11/2026 và hiển thị tiến độ 0/2 bài. | Đạt |
| KT-04 | Thêm bài tập một lần | Thêm Squat kiểm thử, nhóm Tăng cơ, 3 hiệp × 12 lần, 60 kcal, lịch một lần ngày 11/11. | Bài xuất hiện đúng ngày và đúng thông tin. | Thẻ hiển thị đúng dữ liệu, tổng số bài tăng từ 2 lên 3. | Đạt |
| KT-05 | Hiển thị lịch một lần | Chuyển từ 11/11 sang 12/11 rồi quay về 11/11. | Bài Squat chỉ xuất hiện ngày 11/11. | Bài vắng mặt ngày 12/11 và xuất hiện lại khi quay về 11/11. | Đạt |
| KT-06 | Chặn hoàn thành ngày tương lai | Ngày 12/11, bấm ô hoàn thành của Plank. | App chặn thao tác, giữ 0/2 bài và 0 kcal. | App báo không thể đánh dấu hoàn thành cho ngày tương lai. Ô vẫn trống và thống kê giữ nguyên. | Đạt |
| KT-07 | Hoàn thành và thống kê | Đánh dấu Squat ngày 11/11, sau đó mở Thống kê & BMI. | Bài có trạng thái hoàn thành và số liệu hai tab khớp nhau. | Thẻ Squat có nhãn Đã hoàn thành. Hai tab cùng hiện 1/3 bài và 60 kcal ước tính. | Đạt |
| KT-08 | Sửa bài đã hoàn thành | Sửa Squat từ 12 lên 15 lần mỗi hiệp và từ 60 lên 80 kcal. Lưu rồi mở lại biểu mẫu và đối chiếu thống kê. | Thông tin mới được lưu, kết quả đã hoàn thành vẫn giữ số liệu cũ. | Biểu mẫu hiện 15 lần và 80 kcal. Thẻ hoàn thành vẫn hiện 3 hiệp × 12 lần, thống kê vẫn là 60 kcal. | Đạt |
| KT-09 | Ngừng lịch và hoàn tác | Ngừng lịch bài Squat đã hoàn thành. Sau đó ngừng lịch bài Chạy bộ biến tốc chưa hoàn thành rồi bấm Hoàn tác. | Kết quả Squat được giữ. Bài Chạy bộ biến mất khi ngừng và xuất hiện lại sau hoàn tác. | Squat vẫn mở được chi tiết kết quả đã lưu. Tiến độ giảm từ 1/3 xuống 1/2 khi ngừng Chạy bộ, rồi về 1/3 sau hoàn tác. Tổng vẫn là 60 kcal. | Đạt |
| KT-10 | Xem trước và thêm bài gợi ý | Chọn Cardio và T4, xem trước, bỏ chọn Đạp xe tại chỗ rồi thêm vào kế hoạch. | Có 3 bài mẫu và chỉ thêm 2 bài được giữ lại. | App hiển thị 3 mẫu. Lịch có thêm Chạy bộ biến tốc và Nhảy dây nhịp độ vừa, tổng tăng từ 3 lên 5 bài. | Đạt |
| KT-11 | Chống thêm trùng | Chọn lại cùng mục tiêu, cùng T4 và cùng hai bài mẫu của KT-10. | App báo trùng và không thêm bài mới. | App báo cả hai bài đã có cùng lịch. Tiến độ giữ 1/5 bài và 60 kcal. | Đạt |
| KT-12 | Cập nhật BMI | Nhập 70 kg và 175 cm, lưu rồi mở Cá nhân. | Hai tab hiển thị cùng BMI và thông tin cơ thể. | Thống kê & BMI hiện 22.9. Cá nhân hiện 70 kg, 175 cm và BMI 22.9, mức Bình thường. | Đạt |
| KT-13 | Tên hiển thị | Thử lưu tên trống, sau đó lưu tên Người dùng kiểm thử. | Từ chối tên trống và lưu tên hợp lệ. | App báo tên không được để trống. Sau lần lưu hợp lệ, hồ sơ hiện Người dùng kiểm thử. | Đạt |
| KT-14 | Hướng dẫn và giới thiệu | Mở Hướng dẫn sử dụng và Về ứng dụng trong Cá nhân. | Hai mục mở được và hiển thị đúng nội dung. | Hướng dẫn có 7 mục. Về ứng dụng hiển thị FitPlan, học phần tại HUTECH và lưu trữ cục bộ. | Đạt |
| KT-15 | Đăng xuất và đăng nhập lại | Thử Hủy, sau đó xác nhận đăng xuất, bấm Quay lại của Android và đăng nhập lại. | Hủy giữ phiên hiện tại. Xác nhận đưa về đăng nhập. Quay lại không mở màn hình bên trong. Dữ liệu còn sau đăng nhập lại. | Hủy giữ tab Cá nhân và tên hiện tại. Xác nhận đưa về đăng nhập. Quay lại đưa ra màn hình chính Android. Đăng nhập lại vẫn có 1/5 bài, 60 kcal, tên và BMI 22.9. | Đạt |
| KT-16 | Lưu dữ liệu khi mở lại app | Dừng app khi đang đăng nhập rồi chạy lại trên cùng máy ảo. | Lịch, kết quả hoàn thành, tên và BMI vẫn còn. | App vẫn hiện 1/5 bài, 60 kcal và Squat đã hoàn thành. Tên, cân nặng, chiều cao và BMI được giữ. | Đạt |
| KT-17 | Chặn cân nặng bằng 0 | Nhập 0 kg, giữ 175 cm rồi bấm cập nhật. | Báo lỗi và giữ BMI đã lưu. | Ô cân nặng báo lỗi, BMI vẫn là 22.9. Phần cuối thông báo lỗi bị cắt trên máy ảo. | Đạt chức năng, có lỗi hiển thị |
| KT-18 | Chặn số hiệp bằng 0 | Trong biểu mẫu thêm bài, đặt số hiệp bằng 0 rồi bấm Lưu bài tập. | Biểu mẫu giữ nguyên và báo lỗi ở ô số hiệp. | App giữ biểu mẫu và báo số hiệp phải là số nguyên dương. | Đạt |
| KT-19 | Lịch lặp và trạng thái theo ngày | Tạo Lịch tuần kiểm thử lặp T4. So sánh các ngày 11/11, 12/11 và 18/11. | Bài chỉ hiện vào T4 và trạng thái hoàn thành độc lập theo ngày. | Bài hiện ngày 11/11 và 18/11, vắng ngày 12/11. Ngày 11/11 đã hoàn thành, ngày 18/11 vẫn chưa đánh dấu. | Đạt |
| KT-20 | Tên dài và bàn phím | Lưu bài có tên dài. Mở biểu mẫu sửa và chạm ô tên để bật bàn phím. | Tên hiển thị vừa thẻ. Nút thao tác vẫn nhìn thấy khi mở bàn phím. | Tên xuống hai dòng trong danh sách. Khi bàn phím mở, hai nút Hủy và Cập nhật vẫn nhìn thấy. | Đạt phần hiển thị |
| KT-21 | Xem trước các mục tiêu còn lại | Chọn Tăng cơ và Vận động tổng hợp, lần lượt xem trước với lịch T4. | Mỗi mục tiêu hiển thị 3 bài mẫu đúng nhóm. | Tăng cơ có 3 bài nhóm Tăng cơ. Vận động tổng hợp có 3 bài thuộc ba nhóm Tăng cơ, Cardio và Thể lực. | Đạt |

## Vấn đề quan sát được

- **KT-17:** Thông báo lỗi cân nặng bị cắt ở cuối trên Medium Phone API 37.0. Để tái hiện, mở Thống kê & BMI, nhập `0` kg và `175` cm rồi bấm Cập nhật chỉ số cơ thể. App vẫn chặn dữ liệu sai và giữ BMI cũ. Có thể điều chỉnh giao diện để hiển thị trọn thông báo.

## Phạm vi chưa kiểm tra

- Email sai định dạng và nút hiện/ẩn mật khẩu.
- Các lối tắt Xem tiến độ, Cập nhật chỉ số cơ thể và Vào ứng dụng trên màn hình chào.
- Hủy hộp xác nhận ngừng lịch.
- Chiều cao không hợp lệ.
- Tự chọn đơn vị giây và phút trong biểu mẫu. Hai đơn vị này đã quan sát được trên thẻ bài mẫu.
- Cuộn biểu mẫu khi bàn phím đang mở.
- Kiểm thử trên điện thoại Android thật hoặc kích thước màn hình khác.

## Ảnh minh chứng

- [KT-06 — Chặn đánh dấu hoàn thành vào ngày tương lai](images/kiem-thu/kt-06-chan-ngay-tuong-lai.png)
- [KT-09 — Thông báo ngừng lịch có nút Hoàn tác](images/kiem-thu/kt-09-ngung-lich.png)
- [KT-09 — Bài tập xuất hiện lại sau khi hoàn tác](images/kiem-thu/kt-09-hoan-tac.png)
- [KT-11 — Thông báo chặn thêm hai bài trùng lịch](images/kiem-thu/kt-11-chong-trung.png)
- [KT-17 — Thông báo lỗi cân nặng bị cắt ở cuối](images/kiem-thu/kt-17-loi-hien-thi-bmi.png)