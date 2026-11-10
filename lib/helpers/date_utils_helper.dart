// =============================================
// TIỆN ÍCH XỬ LÝ NGÀY ĐỊA PHƯƠNG (LOCAL DATE)
// Tránh lệch ngày do chuyển đổi múi giờ UTC
// =============================================

class DateUtilsHelper {
  static final RegExp _dateKeyRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Chuẩn hóa DateTime về ngày địa phương tại mốc 00:00:00
  static DateTime normalizeLocalDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Chuyển DateTime sang khóa ngày địa phương 'yyyy-MM-dd'
  static String toDateKey(DateTime date) {
    final local = normalizeLocalDate(date);
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Thử phân tích chuỗi 'yyyy-MM-dd' sang DateTime địa phương.
  /// Trả về null nếu sai định dạng hoặc ngày không hợp lệ (vd: 2026-02-30).
  static DateTime? tryParseDateKey(String? dateKey) {
    if (dateKey == null) return null;
    final match = _dateKeyRegex.firstMatch(dateKey.trim());
    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  /// Kiểm tra chuỗi có phải khóa ngày 'yyyy-MM-dd' hợp lệ không
  static bool isValidDateKey(String? dateKey) {
    return tryParseDateKey(dateKey) != null;
  }

  /// Phân tích chuỗi 'yyyy-MM-dd' hợp lệ sang DateTime địa phương.
  /// Ném FormatException nếu không hợp lệ.
  static DateTime parseDateKey(String dateKey) {
    final parsed = tryParseDateKey(dateKey);
    if (parsed == null) {
      throw FormatException('Khóa ngày không hợp lệ: $dateKey');
    }
    return parsed;
  }

  /// Cộng/trừ số ngày trên khóa 'yyyy-MM-dd' theo lịch địa phương
  static String addDaysToKey(String dateKey, int days) {
    final dt = parseDateKey(dateKey);
    final shifted = DateTime(dt.year, dt.month, dt.day + days);
    return toDateKey(shifted);
  }

  /// Định dạng hiển thị 'dd/MM/yyyy' từ DateTime
  static String formatDisplayDate(DateTime date) {
    final local = normalizeLocalDate(date);
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  /// Định dạng hiển thị 'dd/MM/yyyy' từ khóa 'yyyy-MM-dd'
  static String formatDisplayDateKey(String dateKey) {
    final parsed = tryParseDateKey(dateKey);
    if (parsed == null) return dateKey;
    return formatDisplayDate(parsed);
  }

  /// Nhãn thứ ngắn gọn (1 = T2 ... 7 = CN)
  static String weekdayShortLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  /// Nhãn thứ đầy đủ tiếng Việt
  static String weekdayFullLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'Chủ nhật';
      default:
        return '';
    }
  }

  /// Chuỗi mô tả ngày kèm thứ (vd: "Thứ 3, 10/11/2026")
  static String formatFullVietnameseDate(DateTime date) {
    final local = normalizeLocalDate(date);
    return '${weekdayFullLabel(local.weekday)}, ${formatDisplayDate(local)}';
  }

  /// Định dạng danh sách thứ trong tuần (vd: [1, 4] -> "T2, T5")
  static String formatRepeatDays(List<int> repeatDays) {
    final sorted = repeatDays.toSet().toList()..sort();
    if (sorted.length == 7) return 'Mỗi ngày';
    if (sorted.isEmpty) return 'Chưa chọn thứ';
    return sorted.map(weekdayShortLabel).join(', ');
  }
}
