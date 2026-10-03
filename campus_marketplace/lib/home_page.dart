import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/item.dart';
import 'models/cart_model.dart';
import 'repositories/item_repository.dart';
import 'repositories/favorites_repository.dart';
import 'widgets/item_list_section.dart';
import 'cart_page.dart';
import 'services/gemini_service.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  final FavoritesRepository favoritesRepository;
  final int favoritesVersion;

  const HomePage({
    super.key,
    required this.repository,
    required this.favoritesRepository,
    this.favoritesVersion = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
  }

  void _retry() {
    setState(() {
      _itemsFuture = widget.repository.getItems();
    });
  }

  // ปุ่มทดสอบชั่วคราวสำหรับ Checkpoint 2.1 เท่านั้น: ทดสอบว่า GeminiService เชื่อมต่อ API ได้ถูกต้อง
  Future<void> _testGemini() async {
    try {
      final result = await GeminiService().generateText(
        'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง',
      );
      debugPrint('Gemini response: $result');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } catch (e) {
      debugPrint('Gemini error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart),
                // .watch ทำให้ตัวเลขนี้อัปเดตเองทุกครั้งที่ CartModel เปลี่ยน ไม่ว่าจะเปลี่ยนจากจุดไหน
                Text(' ${context.watch<CartModel>().itemCount}'),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is Exception
                ? snapshot.error.toString().replaceFirst('Exception: ', '')
                : 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          final catalog = snapshot.data ?? [];
          return ItemListSection(
            catalog: catalog,
            favoritesRepository: widget.favoritesRepository,
            favoritesVersion: widget.favoritesVersion,
          );
        },
      ),
      // ปุ่มทดสอบชั่วคราวสำหรับ Checkpoint 2.1 เท่านั้น
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testGemini,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('ทดสอบ Gemini'),
      ),
    );
  }
}
