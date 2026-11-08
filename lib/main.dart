import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WorkoutProvider()..loadData(),
      child: const FitPlanApp(),
    ),
  );
}

class FitPlanApp extends StatelessWidget {
  const FitPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitPlan HUTECH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          return provider.isLoggedIn
              ? const DashboardScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}

// ==========================================
// 1. MODEL & JSON SERIALIZATION (BÀI 6 - P1)
// ==========================================
class Exercise {
  final String id;
  final String title;
  final String category; // 'Tăng cơ', 'Cardio', 'Thể lực'
  final int sets;
  final int reps;
  final int calories;
  final String dayOfWeek;
  final String notes;
  bool isCompleted;

  Exercise({
    required this.id,
    required this.title,
    required this.category,
    required this.sets,
    required this.reps,
    required this.calories,
    required this.dayOfWeek,
    this.notes = 'Khởi động kỹ 5 phút trước khi tập, hít thở đều.',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'sets': sets,
        'reps': reps,
        'calories': calories,
        'dayOfWeek': dayOfWeek,
        'notes': notes,
        'isCompleted': isCompleted,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        category: json['category'] ?? 'Tăng cơ',
        sets: json['sets'] ?? 3,
        reps: json['reps'] ?? 12,
        calories: json['calories'] ?? 100,
        dayOfWeek: json['dayOfWeek'] ?? 'Hôm nay',
        notes: json['notes'] ?? 'Khởi động kỹ 5 phút trước khi tập.',
        isCompleted: json['isCompleted'] ?? false,
      );
}

// ==================================================
// 2. STATE MANAGEMENT VỚI PROVIDER (BÀI 7)
// ==================================================
class WorkoutProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userEmail = '';
  double _weight = 68.0;
  double _height = 172.0;
  List<Exercise> _exercises = [];

  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  double get weight => _weight;
  double get height => _height;
  List<Exercise> get exercises => _exercises;

  double get bmi => _weight / ((_height / 100) * (_height / 100));

  int get completedCount => _exercises.where((e) => e.isCompleted).length;
  int get totalCaloriesBurned => _exercises
      .where((e) => e.isCompleted)
      .fold(0, (sum, item) => sum + item.calories);
  double get progressPercentage =>
      _exercises.isEmpty ? 0.0 : completedCount / _exercises.length;

  List<Exercise> _defaultExercises() => [
        Exercise(
          id: '1',
          title: 'Đẩy ngực với tạ đòn (Bench Press)',
          category: 'Tăng cơ',
          sets: 4,
          reps: 10,
          calories: 180,
          dayOfWeek: 'Thứ 2 - Thứ 5',
          notes: 'Giữ chặt bả vai trên ghế, hạ tạ chạm ngực dưới rồi đẩy thẳng.',
          isCompleted: true,
        ),
        Exercise(
          id: '2',
          title: 'Gánh tạ đòn (Barbell Squat)',
          category: 'Tăng cơ',
          sets: 4,
          reps: 12,
          calories: 240,
          dayOfWeek: 'Thứ 3 - Thứ 6',
          notes: 'Giữ lưng thẳng tự nhiên, mở gối theo hướng mũi chân.',
          isCompleted: false,
        ),
        Exercise(
          id: '3',
          title: 'Chạy bộ biến tốc (HIIT Treadmill)',
          category: 'Cardio',
          sets: 1,
          reps: 20,
          calories: 300,
          dayOfWeek: 'Thứ 4 - Thứ 7',
          notes: 'Chạy nước rút 30 giây, đi bộ chậm 60 giây lặp lại 20 phút.',
          isCompleted: false,
        ),
        Exercise(
          id: '4',
          title: 'Plank siết cơ bụng',
          category: 'Thể lực',
          sets: 3,
          reps: 60,
          calories: 90,
          dayOfWeek: 'Mỗi ngày',
          notes: 'Giữ cơ thể tạo thành một đường thẳng từ đầu đến gót chân.',
          isCompleted: true,
        ),
      ];

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userEmail = prefs.getString('userEmail') ?? 'nhom.doan@hutech.edu.vn';
    _weight = prefs.getDouble('weight') ?? 68.0;
    _height = prefs.getDouble('height') ?? 172.0;

    final String? storedList = prefs.getString('exercises_v2');
    if (storedList != null) {
      final List<dynamic> decoded = jsonDecode(storedList);
      _exercises = decoded.map((e) => Exercise.fromJson(e)).toList();
    } else {
      _exercises = _defaultExercises();
      await _saveExercises();
    }
    notifyListeners();
  }

  Future<void> _saveExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_exercises.map((e) => e.toJson()).toList());
    await prefs.setString('exercises_v2', encoded);
  }

  Future<void> login(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = true;
    _userEmail = email;
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    await prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  // CREATE: Thêm bài tập mới
  Future<void> addExercise(Exercise exercise) async {
    _exercises.insert(0, exercise);
    await _saveExercises();
    notifyListeners();
  }

  // UPDATE: Cập nhật thông tin bài tập
  Future<void> updateExercise(Exercise updated) async {
    final index = _exercises.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _exercises[index] = updated;
      await _saveExercises();
      notifyListeners();
    }
  }

  // UPDATE STATUS: Đổi trạng thái hoàn thành
  Future<void> toggleComplete(String id) async {
    final index = _exercises.indexWhere((e) => e.id == id);
    if (index != -1) {
      _exercises[index].isCompleted = !_exercises[index].isCompleted;
      await _saveExercises();
      notifyListeners();
    }
  }

  // DELETE: Xóa bài tập
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    await _saveExercises();
    notifyListeners();
  }

  Future<void> updateBodyMetrics(double newWeight, double newHeight) async {
    final prefs = await SharedPreferences.getInstance();
    _weight = newWeight;
    _height = newHeight;
    await prefs.setDouble('weight', newWeight);
    await prefs.setDouble('height', newHeight);
    notifyListeners();
  }
}

// ==================================================
// 3. MÀN HÌNH ĐĂNG NHẬP VỚI FORM VALIDATION (BÀI 4)
// ==================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'sv.hutech@edu.vn');
  final _passwordController = TextEditingController();

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      Provider.of<WorkoutProvider>(context, listen: false)
          .login(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công! Chào mừng bạn trở lại.'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, size: 80, color: Colors.teal),
                const SizedBox(height: 16),
                const Text(
                  'FITPLAN PRO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const Text('Ứng dụng Lập kế hoạch Tập thể dục'),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email sinh viên',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Vui lòng nhập Email hợp lệ (có chứa @)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _submitLogin,
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'ĐĂNG NHẬP',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 4. MÀN HÌNH DASHBOARD & BOTTOM NAVIGATION BAR (BÀI 3 & 4)
// =========================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    WorkoutPlanTab(),
    BmiAndStatsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Kế hoạch tập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê & BMI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ nhóm',
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 5. TAB 1: DANH SÁCH KẾ HOẠCH TẬP + ĐẦY ĐỦ CRUD (THÊM/SỬA/XÓA)
// =========================================================
class WorkoutPlanTab extends StatelessWidget {
  const WorkoutPlanTab({super.key});

  // Hộp thoại dùng chung cho cả THÊM MỚI và CẬP NHẬT (SỬA)
  void _showExerciseFormDialog(BuildContext context, {Exercise? existing}) {
    final isEditing = existing != null;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final setsCtrl =
        TextEditingController(text: (existing?.sets ?? 4).toString());
    final repsCtrl =
        TextEditingController(text: (existing?.reps ?? 12).toString());
    final calCtrl =
        TextEditingController(text: (existing?.calories ?? 150).toString());
    final notesCtrl = TextEditingController(
        text: existing?.notes ?? 'Khởi động kỹ 5 phút trước khi tập.');
    String selectedCategory = existing?.category ?? 'Tăng cơ';
    String selectedDay = existing?.dayOfWeek ?? 'Hôm nay';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Cập nhật bài tập' : 'Thêm bài tập mới'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Tên bài tập *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập tên bài tập'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration:
                        const InputDecoration(labelText: 'Nhóm bài tập'),
                    items: ['Tăng cơ', 'Cardio', 'Thể lực']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: setsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Số hiệp (Sets)'),
                          validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: repsCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Số lần (Reps)'),
                          validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: calCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Calo tiêu thụ (kcal)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: 'Lịch tập'),
                    items: [
                      'Hôm nay',
                      'Thứ 2 - Thứ 5',
                      'Thứ 3 - Thứ 6',
                      'Thứ 4 - Thứ 7',
                      'Mỗi ngày'
                    ]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Ghi chú kỹ thuật tập'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final provider =
                      Provider.of<WorkoutProvider>(context, listen: false);
                  final exerciseObj = Exercise(
                    id: isEditing
                        ? existing.id
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text.trim(),
                    category: selectedCategory,
                    sets: int.tryParse(setsCtrl.text) ?? 3,
                    reps: int.tryParse(repsCtrl.text) ?? 10,
                    calories: int.tryParse(calCtrl.text) ?? 100,
                    dayOfWeek: selectedDay,
                    notes: notesCtrl.text.trim(),
                    isCompleted: isEditing ? existing.isCompleted : false,
                  );

                  if (isEditing) {
                    provider.updateExercise(exerciseObj);
                  } else {
                    provider.addExercise(exerciseObj);
                  }

                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'Đã cập nhật "${exerciseObj.title}"!'
                          : 'Đã thêm "${exerciseObj.title}" vào lịch tập!'),
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Cập nhật' : 'Lưu bài tập'),
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại AlertDialog xác nhận trước khi xóa (Bài 4 - Visual Feedback)
  void _confirmDelete(
      BuildContext context, WorkoutProvider provider, Exercise item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content:
            Text('Bạn có chắc chắn muốn xóa bài tập "${item.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.deleteExercise(item.id);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa "${item.title}"'),
                  action: SnackBarAction(
                    label: 'Hoàn tác (Undo)',
                    onPressed: () => provider.addExercise(item),
                  ),
                ),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kế Hoạch Tập Luyện'),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Tất cả'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Tăng cơ'),
              Tab(icon: Icon(Icons.directions_run), text: 'Cardio'),
              Tab(icon: Icon(Icons.bolt), text: 'Thể lực'),
            ],
          ),
        ),
        body: Consumer<WorkoutProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiến độ hoàn thành: ${provider.completedCount}/${provider.exercises.length} bài',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '🔥 ${provider.totalCaloriesBurned} kcal',
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: provider.progressPercentage,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildExerciseList(context, provider, 'Tất cả'),
                      _buildExerciseList(context, provider, 'Tăng cơ'),
                      _buildExerciseList(context, provider, 'Cardio'),
                      _buildExerciseList(context, provider, 'Thể lực'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showExerciseFormDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Thêm bài tập'),
        ),
      ),
    );
  }

  Widget _buildExerciseList(
      BuildContext context, WorkoutProvider provider, String filter) {
    final list = filter == 'Tất cả'
        ? provider.exercises
        : provider.exercises.where((e) => e.category == filter).toList();

    if (list.isEmpty) {
      return const Center(
        child: Text('Chưa có bài tập nào trong mục này.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final item = list[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            // Bấm vào dòng bài tập sẽ chuyển sang Màn hình Chi tiết (Bài 3 - Navigator.push)
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(exercise: item),
                ),
              );
            },
            leading: Checkbox(
              value: item.isCompleted,
              activeColor: Colors.teal,
              onChanged: (_) => provider.toggleComplete(item.id),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration:
                    item.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${item.category} • ${item.sets} hiệp x ${item.reps} lần • ${item.calories} kcal\n📅 ${item.dayOfWeek}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Sửa bài tập',
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () =>
                      _showExerciseFormDialog(context, existing: item),
                ),
                IconButton(
                  tooltip: 'Xóa bài tập',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, provider, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =========================================================
// 6. MÀN HÌNH CHI TIẾT BÀI TẬP (BÀI 3 - NAVIGATOR PUSH/POP)
// =========================================================
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Bài Tập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.teal.shade50,
              child: ListTile(
                leading:
                    const Icon(Icons.fitness_center, size: 40, color: Colors.teal),
                title: Text(
                  exercise.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Nhóm bài tập: ${exercise.category}'),
              ),
            ),
            const SizedBox(height: 20),
            Text('📅 Lịch tập: ${exercise.dayOfWeek}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('🔁 Khối lượng: ${exercise.sets} hiệp x ${exercise.reps} lần',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('🔥 Năng lượng tiêu hao: ${exercise.calories} kcal',
                style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            const Text(
              'Hướng dẫn kỹ thuật:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(exercise.notes, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại danh sách'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 7. TAB 2: TÍNH CHỈ SỐ BMI & THỐNG KÊ (BÀI 3 & BÀI 4)
// =========================================================
class BmiAndStatsTab extends StatefulWidget {
  const BmiAndStatsTab({super.key});

  @override
  State<BmiAndStatsTab> createState() => _BmiAndStatsTabState();
}

class _BmiAndStatsTabState extends State<BmiAndStatsTab> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = Provider.of<WorkoutProvider>(context, listen: false);
    _weightCtrl.text = p.weight.toString();
    _heightCtrl.text = p.height.toString();
  }

  String _bmiEvaluate(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân (Cần tăng cơ & dinh dưỡng)';
    if (bmi < 24.9) return 'Bình thường (Duy trì lịch tập đều đặn)';
    if (bmi < 29.9) return 'Thừa cân (Ưu tiên thêm bài tập Cardio)';
    return 'Béo phì (Cần kết hợp HIIT và thâm hụt Calo)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Thống Kê & Chỉ Số Cơ Thể'), centerTitle: true),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          final bmi = provider.bmi;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'CHỈ SỐ BMI HIỆN TẠI',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bmi.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        Text(
                          _bmiEvaluate(bmi),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cân nặng (kg)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Chiều cao (cm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final w = double.tryParse(_weightCtrl.text) ?? 68.0;
                    final h = double.tryParse(_heightCtrl.text) ?? 172.0;
                    provider.updateBodyMetrics(w, h);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật chỉ số BMI!')),
                    );
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('Cập nhật chỉ số cơ thể'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =========================================================
// 8. TAB 3: HỒ SƠ CÁ NHÂN & THÔNG TIN NHÓM ĐỒ ÁN
// =========================================================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    return Scaffold(
      appBar:
          AppBar(title: const Text('Hồ Sơ & Thông Tin Nhóm'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.teal,
              child: Icon(Icons.group, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              provider.userEmail,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text('Môn: Lập trình trên thiết bị di động - HUTECH'),
            const Divider(height: 32, thickness: 1),
            const ListTile(
              leading: Icon(Icons.storage, color: Colors.teal),
              title: Text('Lưu trữ dữ liệu'),
              subtitle: Text('Local Persistence & JSON Serialization'),
            ),
            const ListTile(
              leading: Icon(Icons.layers, color: Colors.teal),
              title: Text('Quản lý trạng thái'),
              subtitle: Text('Provider (ChangeNotifier & Consumer)'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => provider.logout(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Đăng xuất',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
