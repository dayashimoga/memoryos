import 'package:flutter/material.dart';

class ModelsPage extends StatelessWidget {
  const ModelsPage({super.key});

  static const _models = [
    _Model('Gemma 2 2B Instruct', 'Q4_K_M', '1.6 GB', 'Google', false),
    _Model('Phi 3.5 Mini Instruct', 'Q4_K_M', '2.2 GB', 'Microsoft', false),
    _Model('Qwen 2.5 1.5B Instruct', 'Q4_K_M', '900 MB', 'Alibaba', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Models')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('All models run 100% locally', style: Theme.of(context).textTheme.titleSmall),
                  ]),
                  const SizedBox(height: 4),
                  Text('Models are stored on your device. No data leaves your system.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._models.map((m) => _ModelCard(model: m)),
        ],
      ),
    );
  }
}

class _Model {
  final String name;
  final String quantization;
  final String size;
  final String provider;
  final bool downloaded;
  const _Model(this.name, this.quantization, this.size, this.provider, this.downloaded);
}

class _ModelCard extends StatelessWidget {
  final _Model model;
  const _ModelCard({required this.model});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(model.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (model.downloaded)
                  const Chip(label: Text('Active'))
                else
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Download'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(model.provider)),
                Chip(label: Text(model.size)),
                Chip(label: Text(model.quantization)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
