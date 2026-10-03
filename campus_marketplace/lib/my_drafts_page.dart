import 'dart:io';
import 'package:flutter/material.dart';
import 'database/app_database.dart';
import 'repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _draftsFuture = widget.repository.getAllDrafts();
  }

  void _reload() {
    setState(() {
      _draftsFuture = widget.repository.getAllDrafts();
    });
  }

  Future<void> _delete(ListingDraftRow draft) async {
    await widget.repository.deleteDraft(draft.id);
    if (!mounted) return;
    _reload();
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(child: Text('ยังไม่มีร่างประกาศ'));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final imageFile = File(draft.imagePath);
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  // ไฟล์รูปอาจถูกระบบลบได้ ต้องไม่ให้หน้าพังเมื่อไม่พบไฟล์
                  child: imageFile.existsSync()
                      ? Image.file(imageFile, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                ),
                title: Text(draft.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${draft.category} • แก้ไขล่าสุด ${_formatDate(draft.updatedAt)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(draft),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
