import 'package:flutter/material.dart';

class FileDetailPage extends StatelessWidget {
  final String fileId;
  const FileDetailPage({super.key, required this.fileId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File ID: $fileId', style: Theme.of(context).textTheme.bodySmall),
                  const Divider(),
                  const ListTile(leading: Icon(Icons.calendar_today_outlined), title: Text('Created'), subtitle: Text('—')),
                  const ListTile(leading: Icon(Icons.storage_outlined), title: Text('Size'), subtitle: Text('—')),
                  const ListTile(leading: Icon(Icons.tag), title: Text('Tags'), subtitle: Text('None')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
