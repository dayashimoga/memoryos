import os

def main():
    features_dir = 'features'
    os.makedirs(features_dir, exist_ok=True)

    features = {
        'dashboard': {
            'name': 'Home Dashboard',
            'description': 'Personalized workspace containing AI summaries, storage health index metrics, active project lists, and recent activity.',
            'capabilities': ['Progressive media thumbnail loading', 'Staggered masonry grids display', 'Active memory indexing state widgets'],
            'criteria': ['Dashboard loads within 2 seconds', 'Shows correct storage usage ratio', 'Displays recent index feeds'],
            'dependencies': ['storage', 'preview'],
            'rust': ['memoryos-core-engine'],
            'flutter': ['home_page.dart', 'shared_widgets.dart'],
            'apis': ['memoryos_storage_stats', 'memoryos_list_files'],
            'db': ['files'],
            'tests': ['core_test.dart'],
            'docs': ['docs/architecture/overview.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Startup loading < 3 seconds',
            'accessibility': 'Touch targets >= 48x48 dp',
            'security': 'Sandbox local file isolation',
            'status': 'implemented'
        },
        'search': {
            'name': 'Universal Memory Search',
            'description': 'Hybrid search engine combining full-text indexing, vector embeddings, visual color filters, and natural language query processing.',
            'capabilities': ['Full-text FTS5 matching', 'Color similarity search extraction', 'NLP query mapping'],
            'criteria': ['Search returns matches within 200ms', 'Color bubble matches visual items', 'Search history is persisted'],
            'dependencies': ['ocr', 'ai'],
            'rust': ['search-engine', 'memoryos-core-engine'],
            'flutter': ['search_page.dart', 'shared_widgets.dart'],
            'apis': ['memoryos_search', 'memoryos_get_file'],
            'db': ['files_fts', 'search_history'],
            'tests': ['core_test.dart', 'search_engine_tests'],
            'docs': ['docs/user-guide/search.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Search response latency < 200ms',
            'accessibility': 'Accessible search field labeled, screen reader compatible',
            'security': 'FTS indexing handles secure vault boundary checks',
            'status': 'implemented'
        },
        'ocr': {
            'name': 'OCR Extraction Pipeline',
            'description': 'Offline optical character recognition backing document parsing, tesseract extracts, and confidence-score routing.',
            'capabilities': ['Tesseract extraction', 'PaddleOCR validation', 'Bounding box layout checks'],
            'criteria': ['OCR processes images under 5 seconds', 'Returns high confidence text', 'Auto-rotates image targets'],
            'dependencies': ['storage'],
            'rust': ['ocr-engine'],
            'flutter': ['file_detail_page.dart'],
            'apis': ['memoryos_index_file'],
            'db': ['files'],
            'tests': ['core_test.dart', 'ocr_engine_tests'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'OCR latency < 5s per image',
            'accessibility': 'Extracted text exposed to screen reader users',
            'security': 'Vault files undergo sandboxed local OCR only',
            'status': 'implemented'
        },
        'ai': {
            'name': 'AI Intelligence Engine',
            'description': 'Local AI execution backing chat, flashcards, summarization, entity indexing, and automated tags generation.',
            'capabilities': ['Conversational context chat', 'Smart title generator', 'Text summarization'],
            'criteria': ['Summaries generated under 10 seconds', 'Suggested tags match topic scope', 'Offline model downloading works'],
            'dependencies': ['storage'],
            'rust': ['ai-engine'],
            'flutter': ['chat_page.dart', 'models_page.dart'],
            'apis': ['memoryos_chat', 'memoryos_summarize'],
            'db': ['chat_sessions', 'chat_messages'],
            'tests': ['core_test.dart', 'ai_engine_tests'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'AI response latency < 10s',
            'accessibility': 'Semantic headings in markdown reports',
            'security': 'Keyphrase sandbox isolation, local inferences',
            'status': 'implemented'
        },
        'storage': {
            'name': 'Storage Optimizer',
            'description': 'Analytics engine compiling space utilization, cache sizes, heatmaps, and cleanup helpers.',
            'capabilities': ['Heatmap visualizer', 'Space recovery calculations', 'Usage ratio logs'],
            'criteria': ['Analytics updates within 500ms', 'Exposes duplicate sizes', 'Renders visual graphs'],
            'dependencies': [],
            'rust': ['memoryos-core-engine'],
            'flutter': ['duplicates_page.dart', 'home_page.dart'],
            'apis': ['memoryos_storage_stats'],
            'db': ['files'],
            'tests': ['core_test.dart'],
            'docs': ['docs/architecture/overview.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Calculations take < 500ms',
            'accessibility': 'High contrast charts, label readouts',
            'security': 'Read-only storage scanning boundary constraints',
            'status': 'implemented'
        },
        'duplicates': {
            'name': 'Duplicate Clustering',
            'description': 'Near-duplicate image groupings using pHash algorithms and SHA-256 binary validation.',
            'capabilities': ['Perceptual pHash calculations', 'SHA-256 verification checks', 'Similarity rating cluster'],
            'criteria': ['Identifies matching images with different formats', 'Calculates space recovery correctly', 'Validates blurry image frames'],
            'dependencies': ['storage'],
            'rust': ['duplicate-engine'],
            'flutter': ['duplicates_page.dart'],
            'apis': ['memoryos_get_duplicates'],
            'db': ['files'],
            'tests': ['core_test.dart', 'duplicate_engine_tests'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Clustering takes < 1s',
            'accessibility': 'Accessible visual comparison cards, clear delete actions',
            'security': 'Vault files isolated from duplicate clustering scans',
            'status': 'implemented'
        },
        'vault': {
            'name': 'Secure Vault',
            'description': 'Password encrypted vault using AES-256-GCM and Argon2id key derivation.',
            'capabilities': ['AES-256-GCM local encryption', 'Overwrite-before-delete secure deletion', 'Biometrics verification'],
            'criteria': ['Vault files inaccessible without password', 'Decrypts on-the-fly successfully', 'Secure delete wipes blocks'],
            'dependencies': [],
            'rust': ['memoryos-core-engine'],
            'flutter': ['vault_page.dart'],
            'apis': ['memoryos_vault_add', 'memoryos_vault_remove', 'memoryos_vault_list'],
            'db': ['files', 'vault_metadata'],
            'tests': ['core_test.dart'],
            'docs': ['docs/security/audit.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Encryption/decryption overhead < 100ms',
            'accessibility': 'Accessible password fields and dialog notifications',
            'security': 'Argon2id key derivation, zero plain text leaks',
            'status': 'implemented'
        },
        'timeline': {
            'name': 'Chronological Timeline',
            'description': 'Visual index browser grouping screenshots, messages, and files chronologically.',
            'capabilities': ['Day/Week/Month grouping layout', 'Filter indices updates', 'Interactive slider navigations'],
            'criteria': ['Smooth scrolling on timeline stream', 'Correct date header allocations', 'Renders file cards with type markers'],
            'dependencies': ['preview'],
            'rust': ['memoryos-core-engine'],
            'flutter': ['timeline_page.dart'],
            'apis': ['memoryos_list_files'],
            'db': ['files'],
            'tests': ['core_test.dart'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Renders timeline list under 100ms',
            'accessibility': 'Semantic dates readout, keyboard scrolls',
            'security': 'Vault entries omitted from public timeline views',
            'status': 'implemented'
        },
        'collections': {
            'name': 'Smart Collections',
            'description': 'Visual grouping framework managing user-defined tags, collections, and AI suggested tags.',
            'capabilities': ['Folder/collection hierarchies builder', 'Suggested tags matching widgets', 'Drag & drop tags'],
            'criteria': ['Collections list displays count metrics', 'Updates tags instantaneously', 'Re-ranks matching items'],
            'dependencies': ['search'],
            'rust': ['memoryos-core-engine'],
            'flutter': ['collections_page.dart'],
            'apis': ['memoryos_list_files'],
            'db': ['collections', 'file_tags'],
            'tests': ['core_test.dart'],
            'docs': ['docs/user-guide/organization.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Collections load under 150ms',
            'accessibility': 'Accessible list tags screen reader announcements',
            'security': 'Omit vault items from smart category recommendations',
            'status': 'implemented'
        },
        'learning': {
            'name': 'Interactive Learning',
            'description': 'Flashcards and spaced repetition learning module utilizing SuperMemo SM-2 algorithms.',
            'capabilities': ['Flippable card controls', 'Spaced repetition schedule engine', 'Quality metrics feedback'],
            'criteria': ['SM-2 schedules correctly', 'Calculates next interval', 'Remembers ease parameters'],
            'dependencies': ['ai'],
            'rust': ['memoryos-core-engine'],
            'flutter': ['learning_page.dart'],
            'apis': ['memoryos_list_files'],
            'db': ['flashcards', 'learning_records'],
            'tests': ['core_test.dart'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'SM-2 scheduling calculations < 10ms',
            'accessibility': 'Screen reader support for flashcard fronts and backs',
            'security': 'User progress records are completely local and encrypted',
            'status': 'implemented'
        },
        'knowledge_graph': {
            'name': 'Interactive Memory Galaxy',
            'description': 'Verlet physics canvas galaxy graph visualizing nodes, categories, and file relationships.',
            'capabilities': ['Dynamic Verlet node attractions/repulsions', 'Zoom/pan coordinate maps', 'Topic details panels'],
            'criteria': ['Ticks at smooth 60fps frame rates', 'Attracts connected topics', 'Repulses overlapping nodes'],
            'dependencies': ['search'],
            'rust': ['memoryos-core-engine'],
            'flutter': ['galaxy_page.dart'],
            'apis': ['memoryos_search'],
            'db': ['files', 'file_relationships'],
            'tests': ['core_test.dart'],
            'docs': ['docs/architecture/overview.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Renders graph layout at smooth 60fps frame rates',
            'accessibility': 'Text explorer fallback mode list, zoom shortcuts support',
            'security': 'Omit vault records from galaxy node maps',
            'status': 'implemented'
        },
        'converter': {
            'name': 'Universal Digital Toolbox',
            'description': 'Offline format converter supporting EPUB, DOCX, Markdown, HTML, PDF, WAV normalizations, and ZIP creation.',
            'capabilities': ['Markdown ⇄ HTML formatting', 'Native DOCX builder', 'WAV amplitude normalization', 'ZIP compressors'],
            'criteria': ['Converts markdown to PDF outline correctly', 'Normalizes PCM WAV peak amplitudes', 'Unpacks encrypted ZIP packages'],
            'dependencies': [],
            'rust': ['memoryos-core-engine'],
            'flutter': ['toolbox_page.dart', 'rust_ffi.dart'],
            'apis': ['memoryos_convert_document', 'memoryos_process_image', 'memoryos_normalize_wav', 'memoryos_archive_create'],
            'db': [],
            'tests': ['core_test.dart'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Conversion throughput > 10 pages/second',
            'accessibility': 'Accessible sliders, quality selectors, progress logs',
            'security': '100% offline local conversion scans, keyphrase AES backups',
            'status': 'implemented'
        },
        'preview': {
            'name': 'Rich Preview Engine',
            'description': 'Preview generation engine supporting images, markdown, code, and generic previews.',
            'capabilities': ['Progressive thumbnail preview overlays', 'Type matching file icons display', 'Vault secure preview frames'],
            'criteria': ['Previews load under 100ms', 'Shows correct file metadata parameters', 'Renders markdown layout cleanly'],
            'dependencies': [],
            'rust': ['memoryos-core-engine'],
            'flutter': ['file_detail_page.dart', 'shared_widgets.dart'],
            'apis': ['memoryos_get_file'],
            'db': ['files'],
            'tests': ['core_test.dart'],
            'docs': ['docs/architecture/overview.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Preview load latency < 100ms',
            'accessibility': 'Alt-text descriptions generated, accessible focus',
            'security': 'Sandboxed preview render boundary constraints',
            'status': 'implemented'
        },
        'automation': {
            'name': 'File Monitoring Automation',
            'description': 'Directory watching daemon tracking creation, renames, and deletions in watched paths.',
            'capabilities': ['Auto-indexing worker schedules', 'FS event notifications parser', 'Watched folders dashboard'],
            'criteria': ['Indices file creation events correctly', 'Deletes entries on file loss', 'Excludes non-media structures'],
            'dependencies': [],
            'rust': ['memoryos-core-engine'],
            'flutter': ['settings_page.dart'],
            'apis': ['memoryos_index_file'],
            'db': ['watched_directories'],
            'tests': ['core_test.dart'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Auto-indices folder updates in < 1s',
            'accessibility': 'Watched paths list screen reader accessible',
            'security': 'Directory scans restricted to selected watched paths only',
            'status': 'implemented'
        },
        'settings': {
            'name': 'System Preferences',
            'description': 'System preferences console managing active models, database paths, language options, and user preferences.',
            'capabilities': ['Theme selectors widgets', 'Selected AI model controllers', 'Watched directories listings'],
            'criteria': ['Switches themes and colors immediately', 'Shows model download sizes correctly', 'Persists user values'],
            'dependencies': [],
            'rust': ['memoryos-core-engine'],
            'flutter': ['settings_page.dart', 'settings_bloc.dart'],
            'apis': [],
            'db': ['settings'],
            'tests': ['core_test.dart'],
            'docs': ['docs/requirements/functional-requirements.md'],
            'platforms': ['Android', 'iOS', 'Windows', 'macOS', 'Linux', 'Web'],
            'perf': 'Configuration changes update < 50ms',
            'accessibility': 'Full screen contrast modes support, touch feedback target checks',
            'security': 'User preferences configuration sandbox parameters',
            'status': 'implemented'
        }
    }

    for f_id, data in features.items():
        yaml_content = f"""# MemoryOS Feature Specification
id: {f_id}
name: "{data['name']}"
description: "{data['description']}"
status: {data['status']}
supported_platforms:
"""
        for p in data['platforms']:
            yaml_content += f"  - {p}\n"
        
        yaml_content += "expected_capabilities:\n"
        for cap in data['capabilities']:
            yaml_content += f"  - \"{cap}\"\n"
            
        yaml_content += "acceptance_criteria:\n"
        for crit in data['criteria']:
            yaml_content += f"  - \"{crit}\"\n"

        yaml_content += "dependencies:\n"
        for dep in data['dependencies']:
            yaml_content += f"  - {dep}\n"

        yaml_content += "rust_modules:\n"
        for rm in data['rust']:
            yaml_content += f"  - {rm}\n"

        yaml_content += "flutter_modules:\n"
        for fm in data['flutter']:
            yaml_content += f"  - {fm}\n"

        yaml_content += "apis:\n"
        for api in data['apis']:
            yaml_content += f"  - {api}\n"

        yaml_content += "database_objects:\n"
        for db in data['db']:
            yaml_content += f"  - {db}\n"

        yaml_content += "tests:\n"
        for t in data['tests']:
            yaml_content += f"  - {t}\n"

        yaml_content += "docs:\n"
        for doc in data['docs']:
            yaml_content += f"  - {doc}\n"

        yaml_content += f"""performance_targets: "{data['perf']}"
accessibility_requirements: "{data['accessibility']}"
security_requirements: "{data['security']}"
"""
        filepath = os.path.join(features_dir, f"{f_id}.yaml")
        with open(filepath, 'w') as f:
            f.write(yaml_content.strip() + "\n")
        print(f"Generated feature specification: {filepath}")

if __name__ == '__main__':
    main()
