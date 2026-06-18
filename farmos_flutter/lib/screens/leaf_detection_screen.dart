import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_service.dart';

class LeafDetectionScreen extends StatefulWidget {
  const LeafDetectionScreen({super.key});

  @override
  State<LeafDetectionScreen> createState() => _LeafDetectionScreenState();
}

class _LeafDetectionScreenState extends State<LeafDetectionScreen> {
  Uint8List? _imageBytes;
  String? _filename;
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  Future<void> _pickAndDetect() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _filename = image.name;
      _result = null;
      _error = null;
      _loading = true;
    });

    try {
      final result = await ApiService.detectLeafDisease(bytes, image.name);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F3),
        elevation: 0,
        title: const Text(
          'Leaf AI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _loading ? null : _pickAndDetect,
                child: Container(
                  width: double.infinity,
                  height: 230,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1B4332,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Color(0xFF1B4332),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Upload Leaf Image',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        ),
                ),
              ),
              if (_filename != null) ...[
                const SizedBox(height: 8),
                Text(
                  _filename!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _pickAndDetect,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _imageBytes == null ? 'Choose Image' : 'Try Another Image',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Color(0xFF1B4332)),
                  ),
                )
              else if (_error != null)
                _MessageBox(
                  color: Colors.red,
                  icon: Icons.error_outline_rounded,
                  title: 'Detection failed',
                  message: _error!,
                )
              else if (_result != null)
                _DetectionResult(result: _result!),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionResult extends StatelessWidget {
  final Map<String, dynamic> result;

  const _DetectionResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final confidence = result['confidence']?.toString() ?? '-';
    final solutions = result['solutions'] is Map
        ? Map<String, dynamic>.from(result['solutions'] as Map)
        : <String, dynamic>{};
    final immediateActions = _firstNonEmptyList([
      solutions['immediate_actions'],
      result['action'],
    ]);
    final treatment = _firstNonEmptyList([
      solutions['treatment'],
      result['recommendation'],
    ]);
    final prevention = _firstNonEmptyList([
      solutions['prevention'],
      result['prevention'],
    ]);
    final hasDetailedGuidance =
        immediateActions.isNotEmpty ||
        treatment.isNotEmpty ||
        prevention.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Color(0xFF1B4332)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['disease']?.toString() ??
                      result['label']?.toString() ??
                      'Detected Disease',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4332),
                  ),
                ),
              ),
              Text(
                '$confidence%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF52B788),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.grass_rounded,
                label: result['crop']?.toString() ?? 'Unknown crop',
              ),
              _InfoChip(
                icon: Icons.science_rounded,
                label: result['diseaseType']?.toString() ?? 'Unknown type',
              ),
              _InfoChip(
                icon: result['isHealthy'] == true
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                label: result['isHealthy'] == true
                    ? 'Healthy'
                    : 'Needs attention',
              ),
            ],
          ),
          _ResultRow(label: 'Visual Cues', value: result['keyVisualCues']),
          _ListSection(
            title: 'Immediate Actions',
            icon: Icons.priority_high_rounded,
            color: const Color(0xFFE53935),
            items: immediateActions,
          ),
          _ListSection(
            title: 'Treatment',
            icon: Icons.medical_services_rounded,
            color: const Color(0xFF1B4332),
            items: treatment,
          ),
          _ListSection(
            title: 'Prevention',
            icon: Icons.shield_rounded,
            color: const Color(0xFF2196F3),
            items: prevention,
          ),
          if (!hasDetailedGuidance)
            const _MessageBox(
              color: Color(0xFFFF9800),
              icon: Icons.info_outline_rounded,
              title: 'No detailed guide found',
              message:
                  'The model returned this disease name, but no matching solution details were found. Inspect symptoms manually and consult a local agronomist before applying treatment.',
            ),
          _ListSection(
            title: 'Symptoms to Check',
            icon: Icons.visibility_rounded,
            color: const Color(0xFFFF9800),
            items: _asStringList(result['visualSymptoms']),
          ),
          _ListSection(
            title: 'Can Be Confused With',
            icon: Icons.compare_arrows_rounded,
            color: const Color(0xFF7B1FA2),
            items: _asStringList(result['confusableWith']),
          ),
        ],
      ),
    );
  }

  List<String> _asStringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value != null && value.toString().trim().isNotEmpty) {
      return [value.toString().trim()];
    }
    return [];
  }

  List<String> _firstNonEmptyList(List<Object?> values) {
    for (final value in values) {
      final items = _asStringList(value);
      if (items.isNotEmpty) return items;
    }
    return [];
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final Object? value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value.toString().trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Color(0xFF1B4332),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1B4332)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B4332),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ListSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.38,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String message;

  const _MessageBox({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
