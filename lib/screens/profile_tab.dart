import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workout_provider.dart';

// =========================================================
// 8. TAB 3: HỒ SƠ CÁ NHÂN & THÔNG TIN NHÓM ĐỒ ÁN
// =========================================================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ & Thông Tin Nhóm'),
        centerTitle: true,
      ),
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
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
