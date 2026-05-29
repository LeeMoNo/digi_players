import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/secure_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digi Players')),
      body: Center(
        child: Column(
          children: [
            Text('已进入主页面'),
            TextButton(
              onPressed: () async {
                // 临时调试用，确认 DID 已正确存储
                var did = await SecureStorage.getDID();
                debugPrint('MY DID: $did');
                // 输出示例：MY DID: did:key:z6MkhaXgBZDvotDkL5257fai...
              },
              child: Text('确认 DID 已正确存储'),
            ),
            TextButton(
              onPressed: () async {
                context.push('/learn');
              },
              child: Text('学习系统入口'),
            ),
          ],
        ),
      ),
    );
  }
}