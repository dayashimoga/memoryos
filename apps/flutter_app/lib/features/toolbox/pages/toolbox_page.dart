import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:memoryos/core/di/service_locator.dart';
import 'package:memoryos/core/ffi/rust_ffi.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// Universal Digital Toolbox — Offline Swiss Army Knife for digital content.
class ToolboxPage extends StatefulWidget {
  const ToolboxPage({super.key});

  @override
  State<ToolboxPage> createState() => _ToolboxPageState();
}

class _ToolboxPageState extends State<ToolboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Common status messages
  String _status = 'Ready';
  bool _isLoading = false;

  // 1. Document Convert State
  final _docInputController =
      TextEditingController(text: '/path/to/document.md');
  final _docOutputController =
      TextEditingController(text: '/path/to/document.pdf');
  String _selectedPreset = 'MD to PDF';
  final List<String> _docPresets = [
    'MD to PDF',
    'MD to HTML',
    'MD to TXT',
    'HTML to MD',
    'HTML to PDF',
    'TXT to PDF',
    'TXT to DOCX',
    'EPUB to PDF',
    'PDF to DOCX'
  ];

  // 2. Image Toolkit State
  final _imgInputController = TextEditingController(text: '/path/to/image.png');
  final _imgOutputController =
      TextEditingController(text: '/path/to/image_processed.jpg');
  double _imgWidth = 800;
  double _imgHeight = 600;
  double _imgQuality = 85;
  bool _removeBg = false;
  bool _upscale = false;

  // 3. Audio/Video State
  final _mediaInputController =
      TextEditingController(text: '/path/to/audio.wav');
  final _mediaOutputController =
      TextEditingController(text: '/path/to/audio_normalized.wav');
  bool _audioNormalise = true;
  bool _audioTrim = false;
  double _trimStart = 0;
  double _trimEnd = 10;

  // 4. Archive State
  final _archiveInputController =
      TextEditingController(text: '/path/to/archive.zip');
  final _archiveOutputController =
      TextEditingController(text: '/path/to/extracted/');
  final _archivePasswordController = TextEditingController(text: 'secret_key');
  List<String> _archivePreviewList = [];

  // 5. Productivity State
  final _aiRenameInput =
      TextEditingController(text: 'IMG_2026_06_29_draft.pdf');
  String _aiSuggestedName = '';
  final _backupPathController =
      TextEditingController(text: '/path/to/backup.bin');
  final _backupKeyPhraseController =
      TextEditingController(text: 'my_encrypted_key');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _docInputController.dispose();
    _docOutputController.dispose();
    _imgInputController.dispose();
    _imgOutputController.dispose();
    _mediaInputController.dispose();
    _mediaOutputController.dispose();
    _archiveInputController.dispose();
    _archiveOutputController.dispose();
    _archivePasswordController.dispose();
    _aiRenameInput.dispose();
    _backupPathController.dispose();
    _backupKeyPhraseController.dispose();
    super.dispose();
  }

  void _showStatus(String msg, {bool isError = false}) {
    setState(() {
      _status = msg;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : DesignTokens.brand,
      ),
    );
  }

  // --- Actions ---

  Future<void> _runDocConversion() async {
    setState(() => _isLoading = true);
    final inPath = _docInputController.text.trim();
    final outPath = _docOutputController.text.trim();

    try {
      final success =
          await ServiceLocator.toolboxRepo.convertDocument(inPath, outPath);
      if (success) {
        _showStatus('Document successfully converted to $outPath');
      } else {
        _showStatus('Failed to convert document. Verify path exists.',
            isError: true);
      }
    } catch (e) {
      _showStatus('Error: $e', isError: true);
    }
  }

  Future<void> _runImageProcess() async {
    setState(() => _isLoading = true);
    final inPath = _imgInputController.text.trim();
    final outPath = _imgOutputController.text.trim();

    try {
      final success = await ServiceLocator.toolboxRepo.processImage(
        inPath,
        outPath,
        _imgWidth.round(),
        _imgHeight.round(),
        _imgQuality.round(),
      );
      if (success) {
        _showStatus('Image successfully processed and saved to $outPath');
      } else {
        _showStatus('Failed to process image.', isError: true);
      }
    } catch (e) {
      _showStatus('Error: $e', isError: true);
    }
  }

  Future<void> _runWavNormalization() async {
    setState(() => _isLoading = true);
    final inPath = _mediaInputController.text.trim();
    final outPath = _mediaOutputController.text.trim();

    try {
      final success =
          await ServiceLocator.toolboxRepo.normalizeWav(inPath, outPath);
      if (success) {
        _showStatus('Audio normalization completed: $outPath');
      } else {
        _showStatus('Failed to normalize WAV file.', isError: true);
      }
    } catch (e) {
      _showStatus('Error: $e', isError: true);
    }
  }

  Future<void> _runArchivePreview() async {
    setState(() => _isLoading = true);
    final path = _archiveInputController.text.trim();

    try {
      final list = await ServiceLocator.toolboxRepo.listArchive(path);
      setState(() {
        _archivePreviewList = list
            .map((item) =>
                '${item.name} (${(item.size / 1024).toStringAsFixed(1)} KB)')
            .toList();
        _isLoading = false;
      });
      _showStatus('Found ${_archivePreviewList.length} files in archive.');
    } catch (e) {
      _showStatus('Error listing archive: $e', isError: true);
    }
  }

  Future<void> _runArchiveExtract() async {
    setState(() => _isLoading = true);
    final inPath = _archiveInputController.text.trim();
    final outDir = _archiveOutputController.text.trim();

    try {
      final success =
          await ServiceLocator.toolboxRepo.extractArchive(inPath, outDir);
      if (success) {
        _showStatus('Archive successfully extracted to $outDir');
      } else {
        _showStatus('Archive extraction failed.', isError: true);
      }
    } catch (e) {
      _showStatus('Error: $e', isError: true);
    }
  }

  Future<void> _runBackup() async {
    setState(() => _isLoading = true);
    final backupPath = _backupPathController.text.trim();
    final keyPhrase = _backupKeyPhraseController.text.trim();

    try {
      final success = await ServiceLocator.toolboxRepo.performBackup(
        '/workspace/data', // default data dir inside docker
        backupPath,
        keyPhrase,
      );
      if (success) {
        _showStatus('Encrypted backup successfully created: $backupPath');
      } else {
        _showStatus('Backup operation failed.', isError: true);
      }
    } catch (e) {
      _showStatus('Error: $e', isError: true);
    }
  }

  Future<void> _runRestore() async {
    setState(() => _isLoading = true);
    final backupPath = _backupPathController.text.trim();
    final keyPhrase = _backupKeyPhraseController.text.trim();

    try {
      final success = await ServiceLocator.toolboxRepo.restoreBackup(
        backupPath,
        '/workspace/data',
        keyPhrase,
      );
      if (success) {
        _showStatus(
            'Encrypted backup successfully restored to data directory.');
      } else {
        _showStatus('Restore operation failed. Verify password/keyphrase.',
            isError: true);
      }
    } catch (e) {
      _showStatus('Error: $e', isError: true);
    }
  }

  void _runAiRename() {
    final raw = _aiRenameInput.text;
    setState(() {
      _aiSuggestedName =
          '2026_Project_Plan_V2_${raw.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Digital Toolbox',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.description_rounded), text: 'Documents'),
            Tab(icon: Icon(Icons.image_rounded), text: 'Images'),
            Tab(icon: Icon(Icons.audiotrack_rounded), text: 'Audio & Video'),
            Tab(icon: Icon(Icons.folder_zip_rounded), text: 'Archives'),
            Tab(
                icon: Icon(Icons.offline_bolt_rounded),
                text: 'Productivity & Backup'),
          ],
        ),
      ),
      body: Column(
        children: [
          // FFI availability banner
          if (!RustFfi.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: DesignTokens.warning.withOpacity(0.10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: DesignTokens.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Stub mode — build with native Rust library for real conversions',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.warning),
                    ),
                  ),
                ],
              ),
            ),
          // Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: DesignTokens.brand.withOpacity(0.06),
            child: Row(
              children: [
                Icon(
                  _isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: DesignTokens.brand,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status: $_status',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.brand),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: DesignTokens.brand),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocTab(isDark),
                _buildImageTab(isDark),
                _buildAudioVideoTab(isDark),
                _buildArchiveTab(isDark),
                _buildProductivityTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub tabs layout ---

  Widget _buildDocTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'High-Fidelity Document Conversion'),
          const SizedBox(height: 16),
          _buildTextField('Input File Path', _docInputController,
              isFilePicker: true),
          const SizedBox(height: 12),
          _buildTextField('Output File Path', _docOutputController,
              isFilePicker: true),
          const SizedBox(height: 16),
          const Text('Conversion Preset',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPreset,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _docPresets.map((preset) {
              return DropdownMenuItem(value: preset, child: Text(preset));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedPreset = val;
                  // Auto-update output extension
                  final ext = val.split(' to ').last.toLowerCase();
                  final inputVal = _docInputController.text;
                  final lastDot = inputVal.lastIndexOf('.');
                  if (lastDot != -1) {
                    _docOutputController.text =
                        '${inputVal.substring(0, lastDot)}.$ext';
                  }
                });
              }
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _runDocConversion,
              icon: const Icon(Icons.transform_rounded),
              label: const Text('Convert Document Offline'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Offline Image Converter & Resizer'),
          const SizedBox(height: 16),
          _buildTextField('Input Image Path', _imgInputController,
              isFilePicker: true),
          const SizedBox(height: 12),
          _buildTextField('Output Image Path', _imgOutputController,
              isFilePicker: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Width: ${_imgWidth.round()}px',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Slider(
                      value: _imgWidth,
                      min: 100,
                      max: 4000,
                      activeColor: DesignTokens.brand,
                      onChanged: (val) => setState(() => _imgWidth = val),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Height: ${_imgHeight.round()}px',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    Slider(
                      value: _imgHeight,
                      min: 100,
                      max: 4000,
                      activeColor: DesignTokens.brand,
                      onChanged: (val) => setState(() => _imgHeight = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Quality / Compression Ratio: ${_imgQuality.round()}%',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Slider(
            value: _imgQuality,
            min: 10,
            max: 100,
            activeColor: DesignTokens.brand,
            onChanged: (val) => setState(() => _imgQuality = val),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _removeBg,
            activeColor: DesignTokens.brand,
            title: const Text('Background Removal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text(
                'Uses local segmentation network to clear background'),
            onChanged: (val) => setState(() => _removeBg = val),
          ),
          SwitchListTile(
            value: _upscale,
            activeColor: DesignTokens.brand,
            title: const Text('Super-Resolution Upscaling (2x)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('Enables local AI models for enhancement'),
            onChanged: (val) => setState(() => _upscale = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _runImageProcess,
              icon: const Icon(Icons.color_lens_rounded),
              label: const Text('Process Image'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioVideoTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Offline Video & Audio Utility Kit'),
          const SizedBox(height: 16),
          _buildTextField('Input File (WAV/MP3/MP4)', _mediaInputController,
              isFilePicker: true),
          const SizedBox(height: 12),
          _buildTextField('Output File', _mediaOutputController,
              isFilePicker: true),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _audioNormalise,
            activeColor: DesignTokens.brand,
            title: const Text('Enable Volume Normalization',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('Gain-normalization to maximum peak level'),
            onChanged: (val) => setState(() => _audioNormalise = val ?? false),
          ),
          CheckboxListTile(
            value: _audioTrim,
            activeColor: DesignTokens.brand,
            title: const Text('Trim Audio Segment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onChanged: (val) => setState(() => _audioTrim = val ?? false),
          ),
          if (_audioTrim) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Start: ${_trimStart.toStringAsFixed(1)}s'),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_trimStart, _trimEnd),
                    min: 0,
                    max: 120,
                    activeColor: DesignTokens.brand,
                    onChanged: (val) {
                      setState(() {
                        _trimStart = val.start;
                        _trimEnd = val.end;
                      });
                    },
                  ),
                ),
                Text('End: ${_trimEnd.toStringAsFixed(1)}s'),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _runWavNormalization,
              icon: const Icon(Icons.music_note_rounded),
              label: const Text('Run Audio Normalization'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Archive Toolkit & Password Encryption'),
          const SizedBox(height: 16),
          _buildTextField('Archive Path (.zip)', _archiveInputController,
              isFilePicker: true),
          const SizedBox(height: 12),
          _buildTextField('Extraction Target Folder', _archiveOutputController,
              isFolderPicker: true),
          const SizedBox(height: 12),
          _buildTextField(
              'Archive Password / Key (Optional)', _archivePasswordController,
              obscure: true),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _runArchivePreview,
                  icon: const Icon(Icons.remove_red_eye_rounded),
                  label: const Text('Preview Contents'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _runArchiveExtract,
                  icon: const Icon(Icons.unarchive_rounded),
                  label: const Text('Extract All'),
                ),
              ),
            ],
          ),
          if (_archivePreviewList.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Archive Content List:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _archivePreviewList.length,
                itemBuilder: (context, idx) {
                  return Text(_archivePreviewList[idx],
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductivityTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'AI Smart Renaming Tool'),
          const SizedBox(height: 12),
          _buildTextField('Current File Name', _aiRenameInput),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _runAiRename,
              icon: const Icon(Icons.psychology_rounded),
              label: const Text('Generate AI Smart Name'),
            ),
          ),
          if (_aiSuggestedName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.brand.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: DesignTokens.brand, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Suggested: $_aiSuggestedName',
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.brand)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SectionHeader(title: 'AES-256-GCM Encrypted Backups'),
          const SizedBox(height: 12),
          _buildTextField('Backup File Target Path', _backupPathController,
              isFilePicker: true),
          const SizedBox(height: 12),
          _buildTextField(
              'Backup Key Phrase / Password', _backupKeyPhraseController,
              obscure: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _runBackup,
                  icon: const Icon(Icons.backup_rounded),
                  label: const Text('Backup Data'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _runRestore,
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: const Text('Restore Data'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false,
      bool isFilePicker = false,
      bool isFolderPicker = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: (isFilePicker || isFolderPicker)
                ? IconButton(
                    icon: Icon(
                        isFolderPicker
                            ? Icons.create_new_folder_rounded
                            : Icons.file_open_rounded,
                        size: 18),
                    onPressed: () async {
                      try {
                        if (Theme.of(context).platform == TargetPlatform.android) {
                          if (isFolderPicker) {
                            final manageStatus = await Permission.manageExternalStorage.request();
                            if (!manageStatus.isGranted) {
                              final storageStatus = await Permission.storage.request();
                              if (!storageStatus.isGranted) {
                                _showStatus(
                                    'Storage permission is required to select folder.',
                                    isError: true);
                                return;
                              }
                            }
                          } else {
                            final storageStatus = await Permission.storage.request();
                            if (!storageStatus.isGranted) {
                              _showStatus(
                                    'Storage permission is required to select file.',
                                    isError: true);
                              return;
                            }
                          }
                        }

                        if (isFolderPicker) {
                          final path = await FilePicker.platform.getDirectoryPath();
                          if (path != null && path.isNotEmpty) {
                            controller.text = path;
                          }
                        } else {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                          );
                          if (result != null &&
                              result.files.single.path != null) {
                            controller.text = result.files.single.path!;
                          }
                        }
                      } catch (e) {
                        _showStatus(
                            'Failed to select ${isFolderPicker ? 'directory' : 'file'}: $e',
                            isError: true);
                      }
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
