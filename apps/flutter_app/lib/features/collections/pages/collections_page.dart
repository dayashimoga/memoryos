import 'package:flutter/material.dart';

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  static const _collections = [
    ('AWS Security', Icons.security_outlined, Color(0xFF6366F1), 42),
    ('Chess Learning', Icons.sports_esports_outlined, Color(0xFF8B5CF6), 128),
    ('Receipts', Icons.receipt_outlined, Color(0xFF10B981), 23),
    ('Invoices', Icons.request_quote_outlined, Color(0xFFF59E0B), 17),
    ('Meetings', Icons.meeting_room_outlined, Color(0xFF3B82F6), 64),
    ('Kubernetes', Icons.cloud_outlined, Color(0xFF06B6D4), 89),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _collections.length,
        itemBuilder: (context, i) {
          final col = _collections[i];
          return Card(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col.$3.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(col.$2, color: col.$3),
                    ),
                    const Spacer(),
                    Text(col.$1, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${col.$4} files', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
