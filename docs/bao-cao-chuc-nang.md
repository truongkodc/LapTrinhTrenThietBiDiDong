# FITPLAN – TÀI LIỆU MÔ TẢ CHỨC NĂNG ỨNG DỤNG

> **Học phần:** Lập trình trên thiết bị di động (CMP177)  
> **Đồ án:** Ứng dụng lập kế hoạch và theo dõi tập luyện FitPlan  
> **Nhóm:** 7  
> **Trạng thái:** Bản nháp để nhóm đối chiếu với phiên bản ứng dụng thực tế

## 1. Giới thiệu ứng dụng

FitPlan là ứng dụng di động hỗ trợ người dùng lập kế hoạch tập luyện theo ngày, theo dõi tình trạng hoàn thành bài tập, xem thống kê tập luyện và quản lý một số chỉ số cơ thể như BMI. Ứng dụng hướng đến sinh viên và người mới bắt đầu muốn tổ chức hoạt động rèn luyện cá nhân.

Ứng dụng cho phép tạo lịch tập một lần hoặc lặp lại hằng tuần, lựa chọn nhóm bài tập, ghi nhận kết quả hoàn thành theo từng ngày và tham khảo kế hoạch tập mẫu. Dữ liệu được lưu cục bộ trên thiết bị thông qua SharedPreferences; các chức năng chính không yêu cầu kết nối máy chủ trực tuyến.

## 2. Mục tiêu ứng dụng

- Hỗ trợ tạo và quản lý kế hoạch tập luyện theo ngày.
- Thiết lập lịch tập một lần hoặc lặp vào các ngày trong tuần.
- Theo dõi trạng thái hoàn thành bài tập độc lập theo từng ngày.
- Cung cấp thống kê cơ bản về tỷ lệ hoàn thành và kcal ước tính.
- Hỗ trợ tính BMI từ chiều cao và cân nặng do người dùng nhập.
- Đưa ra kế hoạch tập tham khảo dựa trên quy tắc và danh sách bài tập mẫu có sẵn.
- Lưu thông tin và lịch sử tập luyện cục bộ trên thiết bị.

## 3. Đối tượng sử dụng

- Sinh viên muốn chủ động sắp xếp thời gian tập luyện.
- Người mới bắt đầu cần kế hoạch tập đơn giản để tham khảo.
- Người muốn ghi nhận tiến độ tập luyện hằng ngày.
- Người muốn theo dõi BMI và thống kê tập luyện cơ bản.

Ứng dụng hiện phục vụ quản lý cá nhân trên một thiết bị, chưa phải nền tảng quản lý nhiều người dùng hoặc đồng bộ dữ liệu trực tuyến.

## 4. Các chức năng chính

### 4.1. Đăng nhập và đăng xuất cục bộ

Người dùng nhập email và mật khẩu để vào ứng dụng. Ứng dụng kiểm tra định dạng email và yêu cầu mật khẩu tối thiểu 6 ký tự; có nút bật/tắt hiển thị mật khẩu. Trạng thái phiên được lưu trên thiết bị. Khi phiên còn hiệu lực, lần mở tiếp theo có thể chuyển thẳng đến màn hình chính. Khi đăng xuất, ứng dụng hiển thị hộp thoại xác nhận và ngăn thao tác Back quay lại màn hình bên trong.

**Lưu ý:** Đây là đăng nhập cục bộ, không phải xác thực tài khoản với máy chủ.

### 4.2. Màn hình chào sau đăng nhập

Sau khi đăng nhập, ứng dụng hiển thị màn hình chào với các lối tắt: Xem kế hoạch hôm nay, Thêm bài tập mới, Cập nhật BMI và nút Vào ứng dụng để chuyển đến giao diện chính.

### 4.3. Xem kế hoạch tập luyện theo ngày

Người dùng có thể chuyển ngày trước/ngày sau, chọn ngày bằng lịch DatePicker hoặc quay về Hôm nay. Danh sách bài tập trong ngày có thể lọc theo bốn nhóm: Tất cả, Tăng cơ, Cardio và Thể lực.

### 4.4. Thêm và chỉnh sửa bài tập

Người dùng nhập thông tin bài tập và chọn một trong hai kiểu lịch:

- **Tập một lần:** bài tập được lên lịch vào một ngày cụ thể.
- **Lặp hằng tuần:** chọn các thứ trong tuần (T2 đến CN) và ngày bắt đầu áp dụng.

Ứng dụng hỗ trợ đơn vị lần, giây và phút. Nhãn trường nhập thay đổi theo đơn vị được chọn; khối lượng được trình bày theo dạng số hiệp × số lượng và đơn vị tương ứng. Khi sửa lịch, thay đổi áp dụng từ thời điểm hiện tại theo logic ứng dụng nhằm giữ lịch sử các giai đoạn trước.

### 4.5. Ngừng lịch tập và hoàn tác

Người dùng có thể ngừng bài tập khỏi lịch từ hôm nay trở đi sau khi xác nhận. Kết quả đã hoàn thành trong quá khứ hoặc trong ngày hiện tại được giữ lại. Thao tác vừa thực hiện có thể được hoàn tác qua thông báo SnackBar.

### 4.6. Đánh dấu hoàn thành và lưu lịch sử

Người dùng đánh dấu hoàn thành cho ngày đang xem; ứng dụng không cho phép đánh dấu ngày trong tương lai. Khi ghi nhận hoàn thành, ứng dụng lưu snapshot gồm tên bài tập, nhóm, số hiệp, số lượng, đơn vị và kcal ước tính tại thời điểm hoàn thành. Nhờ đó, lịch sử không bị thay đổi khi người dùng sửa hoặc ngừng lịch về sau.

### 4.7. Chi tiết bài tập

Màn hình chi tiết hiển thị thông tin lịch tập, khối lượng, kcal ước tính và ghi chú kỹ thuật (nếu có). Người dùng có thể bật/tắt trạng thái hoàn thành của ngày đang chọn.

### 4.8. Gợi ý kế hoạch tập luyện

Người dùng chọn một trong ba mục tiêu: Tăng cơ, Cardio hoặc Vận động tổng hợp; sau đó chọn các ngày muốn tập trong tuần. Ứng dụng hiển thị trước ba bài tập mẫu cố định. Người dùng có thể bỏ chọn bài không muốn thêm rồi thêm các bài còn lại theo lô. Ứng dụng tự bỏ qua bài mẫu trùng lịch đang hoạt động.

**Bản chất chức năng:** Đây là gợi ý dựa trên bộ quy tắc cố định (rule-based) và danh sách bài tập mẫu. Chức năng **không sử dụng AI**, không gọi dịch vụ AI, không truy vấn mạng và không tự cá nhân hóa theo BMI, thiết bị tập hoặc tiền sử sức khỏe.

### 4.9. Thống kê tập luyện và tính BMI

Khu vực thống kê hiển thị tỷ lệ hoàn thành, tổng kcal ước tính và danh sách bài tập đã hoàn thành của ngày đang chọn. Người dùng nhập cân nặng và chiều cao để tính BMI; phạm vi nhập được kiểm tra theo giới hạn của ứng dụng: cân nặng 10–300 kg và chiều cao 50–250 cm. Kết quả được phân loại để tham khảo.

Giá trị kcal là ước tính minh họa theo dữ liệu được thiết lập cho bài tập, không phải số đo năng lượng tiêu hao thực tế.

### 4.10. Hồ sơ cá nhân và hướng dẫn

Trong tab Cá nhân, người dùng có thể đặt/chỉnh sửa tên hiển thị, xem tóm tắt chỉ số cơ thể, mở hướng dẫn sử dụng, xem thông tin ứng dụng và đăng xuất. Tên hiển thị dài từ 1 đến 50 ký tự; nếu chưa đặt, ứng dụng dùng tên mặc định “Người dùng FitPlan”.

## 5. Cách thao tác cơ bản

### 5.1. Bắt đầu sử dụng
1. Mở FitPlan.
2. Nhập email đúng định dạng và mật khẩu tối thiểu 6 ký tự.
3. Nhấn Đăng nhập.
4. Tại màn hình chào, chọn lối tắt hoặc nhấn Vào ứng dụng.

### 5.2. Xem lịch tập
1. Mở tab Kế hoạch.
2. Dùng nút ngày trước/ngày sau hoặc chọn ngày trên lịch.
3. Chọn bộ lọc Tất cả, Tăng cơ, Cardio hoặc Thể lực.
4. Chọn bài tập để xem chi tiết.

### 5.3. Thêm bài tập
1. Chọn Thêm bài tập.
2. Nhập thông tin theo các trường hiển thị.
3. Chọn đơn vị lần, giây hoặc phút.
4. Chọn lịch một lần hoặc lặp hằng tuần.
5. Nếu lặp, chọn các thứ và ngày bắt đầu.
6. Kiểm tra và lưu bài tập.

### 5.4. Sử dụng gợi ý kế hoạch
1. Mở Gợi ý kế hoạch.
2. Chọn mục tiêu tập luyện.
3. Chọn các ngày tập trong tuần.
4. Xem danh sách bài tập mẫu.
5. Bỏ chọn bài không muốn sử dụng.
6. Thêm các bài còn lại vào kế hoạch.

### 5.5. Đánh dấu hoàn thành
1. Mở kế hoạch và chọn ngày cần cập nhật.
2. Chọn bài tập muốn ghi nhận.
3. Mở chi tiết nếu cần kiểm tra thông tin.
4. Nhấn thao tác đánh dấu hoàn thành.
5. Kiểm tra trạng thái và thống kê trong ngày.

### 5.6. Xem thống kê và tính BMI
1. Mở tab Thống kê/BMI.
2. Chọn ngày để xem tỷ lệ hoàn thành và kcal ước tính.
3. Nhập cân nặng và chiều cao.
4. Thực hiện tính BMI và xem kết quả phân loại.

### 5.7. Đăng xuất
1. Mở tab Cá nhân.
2. Chọn Đăng xuất.
3. Đọc hộp thoại xác nhận.
4. Xác nhận nếu muốn kết thúc phiên.

## 6. Kết quả đạt được

Theo README trên nhánh `main`, FitPlan đã xây dựng các nhóm chức năng: đăng nhập/đăng xuất cục bộ; quản lý lịch tập theo ngày; lịch một lần và lặp hằng tuần; nhiều đơn vị bài tập; ghi nhận hoàn thành kèm snapshot; ngừng lịch và hoàn tác; gợi ý theo quy tắc; thống kê, tính BMI; hồ sơ và hướng dẫn. Dự án sử dụng Flutter/Dart, Provider để quản lý trạng thái và SharedPreferences để lưu dữ liệu cục bộ dưới dạng JSON.

## 7. Hạn chế của ứng dụng

1. **Đăng nhập chưa xác thực trực tuyến:** ứng dụng kiểm tra dữ liệu ở phía thiết bị và lưu phiên cục bộ, chưa có máy chủ xác thực tài khoản.
2. **Dữ liệu chưa tách riêng theo tài khoản:** dữ liệu tập luyện, lịch sử, tên hiển thị và BMI lưu trên thiết bị, chưa đồng bộ hoặc phân vùng độc lập theo email khi đổi người đăng nhập.
3. **Gợi ý chưa sử dụng AI:** kế hoạch được tạo từ quy tắc và bài tập mẫu cố định, chưa học từ hành vi hoặc điều chỉnh theo tình trạng thể chất cá nhân.
4. **Chưa đồng bộ đám mây:** README không mô tả cơ chế đồng bộ trực tuyến trong luồng hoạt động chính.
5. **Kcal chỉ là giá trị ước tính minh họa:** không phản ánh chính xác năng lượng tiêu hao của từng cá nhân và không tự thay đổi theo đơn vị tập.
6. **Theo dõi sức khỏe còn cơ bản:** ứng dụng mới hỗ trợ BMI và thống kê đơn giản, không thay thế tư vấn chuyên môn hoặc thiết bị đo sức khỏe.

## 8. Kết luận

FitPlan hỗ trợ lập kế hoạch và theo dõi tập luyện cá nhân thông qua quản lý lịch tập, ghi nhận hoàn thành, thống kê, tính BMI và gợi ý kế hoạch theo quy tắc. Việc lưu dữ liệu cục bộ giúp các chức năng chính hoạt động mà không cần kết nối mạng. Tuy nhiên, ứng dụng còn giới hạn về xác thực tài khoản, đồng bộ dữ liệu và mức độ cá nhân hóa; đây là những hướng có thể xem xét phát triển trong tương lai.

## 9. Nội dung cần nhóm đối chiếu trước khi chốt

Các nội dung dưới đây được tổng hợp từ README trên nhánh `main`; cần Hữu/nhóm kiểm tra trực tiếp trên bản app demo:

- Tên chính xác của các tab và nút trên giao diện.
- Trình tự thao tác, nhãn trường nhập và thông báo lỗi thực tế.
- Màn hình chào và các lối tắt có đúng như mô tả.
- Hành vi khi sửa/ngừng lịch, hoàn tác và đánh dấu hoàn thành.
- Kết quả hiển thị của thống kê, BMI và gợi ý kế hoạch.
- Ảnh chụp màn hình minh họa cho từng nhóm chức năng.

**Phạm vi:** Tài liệu tập trung vào mô tả chức năng và cách sử dụng. Không viết lại kịch bản kiểm thử chi tiết hoặc kịch bản video demo vì phần đó do thành viên Việt phụ trách.
