// Sketch Digitizer — uploads a survey sketch, calls the Python detection
// service for candidate boundary lines, and lets the farmer confirm/adjust
// before building a final polygon.
//
// IMPORTANT:
// - The backend only finds STRAIGHT lines. It cannot detect curves at all.
// - The backend cannot tell "lot boundary" apart from other thick lines in
//   the image (e.g. a house outline) -- it returns candidates ranked by
//   length/confidence, pre-selecting the longest ones, but you must review.
// - Tuned against one clean printed surveyor-style sketch. Messy handwritten
//   sketches will detect fewer real edges and more noise.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

// Change this if you deploy the Python service somewhere other than localhost.
const String _sketchServiceUrl = 'http://localhost:8000';

class DetectedEdge {
  final Offset p1;
  final Offset p2;
  final double confidence;
  bool selected;
  double? distanceMeters;

  DetectedEdge({
    required this.p1,
    required this.p2,
    required this.confidence,
    this.selected = false,
    this.distanceMeters,
  });

  double get length => (p1 - p2).distance;
}

class ManualPoint {
  Offset pos;
  ManualPoint(this.pos);
}

class SketchDigitizerScreen extends StatefulWidget {
  final int farmId;
  final Future<void> Function(
    String name,
    String soil,
    List<Offset> polygonPx,
    double areaM2,
    double areaAcres,
    String? digitizedDiagram,
  )
  onSave;

  const SketchDigitizerScreen({
    super.key,
    required this.farmId,
    required this.onSave,
  });

  @override
  State<SketchDigitizerScreen> createState() => _SketchDigitizerScreenState();
}

class _SketchDigitizerScreenState extends State<SketchDigitizerScreen> {
  Uint8List? _imageBytes;
  double _imgW = 0, _imgH = 0;
  List<DetectedEdge> _edges = [];
  List<ManualPoint> _manualPoints = [];
  bool _loading = false;
  String? _error;
  double _scaleMetersPerPixel = 1.0;
  bool _scaleSet = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _edges = [];
      _manualPoints = [];
      _error = null;
      _scaleSet = false;
    });
    await _runDetection(bytes);
  }

  Future<void> _runDetection(Uint8List bytes) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$_sketchServiceUrl/digitize');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'sketch.png',
          contentType: MediaType('image', 'png'),
        ),
      );
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        setState(() {
          _error =
              'Detection service returned an error (${response.statusCode}). '
              'You can still digitize manually below.';
          _loading = false;
        });
        return;
      }

      final data = jsonDecode(response.body);
      _imgW = (data['width'] as num).toDouble();
      _imgH = (data['height'] as num).toDouble();

      final rawEdges = (data['edges'] as List)
          .map(
            (e) => DetectedEdge(
              p1: Offset(
                (e['x1'] as num).toDouble(),
                (e['y1'] as num).toDouble(),
              ),
              p2: Offset(
                (e['x2'] as num).toDouble(),
                (e['y2'] as num).toDouble(),
              ),
              confidence: (e['confidence'] as num).toDouble(),
            ),
          )
          .toList();

      rawEdges.sort((a, b) => b.length.compareTo(a.length));
      for (int i = 0; i < rawEdges.length; i++) {
        rawEdges[i].selected = i < 4;
      }

      setState(() {
        _edges = rawEdges;
        _loading = false;
        if (rawEdges.isEmpty) {
          _error =
              'No strong straight lines detected. Use "Add point manually" below instead.';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error =
            'Could not reach the digitizer service at $_sketchServiceUrl.\n'
            'Make sure it is running locally (uvicorn main:app --port 8000).\n'
            'You can still digitize manually below.\n\nDetails: $e';
      });
    }
  }

  Offset _displayToImageCoords(Offset localPos, Size displaySize) {
    final scaleX = _imgW / displaySize.width;
    final scaleY = _imgH / displaySize.height;
    return Offset(localPos.dx * scaleX, localPos.dy * scaleY);
  }

  Offset _imageToDisplayCoords(Offset imgPos, Size displaySize) {
    final scaleX = displaySize.width / _imgW;
    final scaleY = displaySize.height / _imgH;
    return Offset(imgPos.dx * scaleX, imgPos.dy * scaleY);
  }

  void _toggleEdge(int index) {
    setState(() => _edges[index].selected = !_edges[index].selected);
  }

  void _askEdgeDistance(int index) {
    final ctrl = TextEditingController(
      text: _edges[index].distanceMeters?.toStringAsFixed(1) ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edge distance',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'e.g. 154.06',
            suffixText: 'metres',
            filled: true,
            fillColor: const Color(0xFFF4F6F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
            ),
            onPressed: () {
              final d = double.tryParse(ctrl.text.trim());
              if (d != null && d > 0) {
                setState(() {
                  _edges[index].distanceMeters = d;
                  if (!_scaleSet) {
                    _scaleMetersPerPixel = d / _edges[index].length;
                    _scaleSet = true;
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addManualPointAt(Offset imgPos) {
    setState(() => _manualPoints.add(ManualPoint(imgPos)));
  }

  List<Offset> _buildPolygonPoints() {
    final pts = <Offset>[];
    for (final e in _edges.where((e) => e.selected)) {
      pts.add(e.p1);
      pts.add(e.p2);
    }
    for (final m in _manualPoints) {
      pts.add(m.pos);
    }
    if (pts.length < 3) return [];

    final unique = <Offset>[];
    for (final p in pts) {
      final dup = unique.any((u) => (u - p).distance < 20);
      if (!dup) unique.add(p);
    }

    final cx = unique.map((p) => p.dx).reduce((a, b) => a + b) / unique.length;
    final cy = unique.map((p) => p.dy).reduce((a, b) => a + b) / unique.length;
    unique.sort((a, b) {
      final angA = atan2(a.dy - cy, a.dx - cx);
      final angB = atan2(b.dy - cy, b.dx - cx);
      return angA.compareTo(angB);
    });
    return unique;
  }

  double _pixelAreaToM2(double pxArea) =>
      pxArea * _scaleMetersPerPixel * _scaleMetersPerPixel;

  double _polyAreaPx(List<Offset> pts) {
    double a = 0;
    for (int i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      a += pts[i].dx * pts[j].dy - pts[j].dx * pts[i].dy;
    }
    return a.abs() / 2;
  }

  List<double> _edgeDistancesForPolygon(List<Offset> polygon) {
    if (polygon.length < 3) return [];
    return List.generate(polygon.length, (i) {
      final next = (i + 1) % polygon.length;
      return (polygon[i] - polygon[next]).distance * _scaleMetersPerPixel;
    });
  }

  String? _buildDigitizedDiagramJson(List<Offset> polygon) {
    final imageBytes = _imageBytes;
    if (imageBytes == null) return null;

    return jsonEncode({
      'source': 'sketch_digitizer',
      'imageBytesBase64': base64Encode(imageBytes),
      'imageWidth': _imgW,
      'imageHeight': _imgH,
      'scaleMetersPerPixel': _scaleMetersPerPixel,
      'polygonPoints': polygon.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'edgeDistances': _edgeDistancesForPolygon(polygon),
      'selectedEdges': _edges
          .where((e) => e.selected)
          .map(
            (e) => {
              'x1': e.p1.dx,
              'y1': e.p1.dy,
              'x2': e.p2.dx,
              'y2': e.p2.dy,
              'confidence': e.confidence,
              'distanceMeters': e.distanceMeters,
            },
          )
          .toList(),
      'manualPoints': _manualPoints
          .map((p) => {'x': p.pos.dx, 'y': p.pos.dy})
          .toList(),
    });
  }

  void _showFinalizeSheet() {
    final poly = _buildPolygonPoints();
    if (poly.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 3 edges/points to form a shape'),
        ),
      );
      return;
    }
    if (!_scaleSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tap an edge distance field and enter its real distance first',
          ),
        ),
      );
      return;
    }

    final pxArea = _polyAreaPx(poly);
    final m2 = _pixelAreaToM2(pxArea);
    final acres = m2 / 4046.86;
    final nameCtrl = TextEditingController();
    String soil = 'Red Soil';
    final soils = [
      'Red Soil',
      'Black Soil',
      'Sandy Soil',
      'Loamy Soil',
      'Clay Soil',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Save Digitized Plot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${m2.round()} m²',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        Text(
                          'area',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          acres.toStringAsFixed(3),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        Text(
                          'acres',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${poly.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        Text(
                          'points',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Plot name',
                  hintText: 'e.g. North Field',
                  filled: true,
                  fillColor: const Color(0xFFF4F6F3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: soils.map((s) {
                  final sel = soil == s;
                  return GestureDetector(
                    onTap: () => setModal(() => soil = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1B4332)
                            : const Color(0xFFF4F6F3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF1B4332)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await widget.onSave(
                    nameCtrl.text.trim(),
                    soil,
                    poly,
                    m2,
                    acres,
                    _buildDigitizedDiagramJson(poly),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Save Plot',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1B4332)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Digitize Sketch',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ℹ️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This finds straight lines automatically as a starting point. '
                        'It can\'t detect curves, and may pick up other lines by mistake — '
                        'review and adjust before saving.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.brown.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_imageBytes == null)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1B4332,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.upload_rounded,
                            size: 24,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Upload Sketch',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF1B4332),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Detecting straight edges...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),

                    if (!_loading)
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final displayW = constraints.maxWidth;
                          final displayH =
                              displayW * (_imgH == 0 ? 0.6 : _imgH / _imgW);
                          final displaySize = Size(displayW, displayH);

                          return Container(
                            width: displayW,
                            height: displayH,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  Image.memory(
                                    _imageBytes!,
                                    width: displayW,
                                    height: displayH,
                                    fit: BoxFit.fill,
                                  ),
                                  GestureDetector(
                                    onTapDown: (d) {
                                      final imgPos = _displayToImageCoords(
                                        d.localPosition,
                                        displaySize,
                                      );
                                      for (int i = 0; i < _edges.length; i++) {
                                        final mid = Offset(
                                          (_edges[i].p1.dx + _edges[i].p2.dx) /
                                              2,
                                          (_edges[i].p1.dy + _edges[i].p2.dy) /
                                              2,
                                        );
                                        if ((mid - imgPos).distance < 40) {
                                          _toggleEdge(i);
                                          return;
                                        }
                                      }
                                    },
                                    onLongPressStart: (d) {
                                      final imgPos = _displayToImageCoords(
                                        d.localPosition,
                                        displaySize,
                                      );
                                      _addManualPointAt(imgPos);
                                    },
                                    child: CustomPaint(
                                      size: displaySize,
                                      painter: _OverlayPainter(
                                        edges: _edges,
                                        manualPoints: _manualPoints,
                                        toDisplay: (p) => _imageToDisplayCoords(
                                          p,
                                          displaySize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 10),
                    Text(
                      'Tap a colored line to toggle it on/off · Long-press to add a manual point (for curves)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (_edges.isNotEmpty) ...[
                      const Text(
                        'Detected Edges',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._edges.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: e.selected
                                ? const Color(
                                    0xFF52B788,
                                  ).withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: e.selected
                                  ? const Color(0xFF52B788)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: e.selected,
                                activeColor: const Color(0xFF1B4332),
                                onChanged: (_) => _toggleEdge(i),
                              ),
                              Expanded(
                                child: Text(
                                  'Edge ${i + 1} · confidence ${(e.confidence * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _askEdgeDistance(i),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1B4332,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    e.distanceMeters != null
                                        ? '${e.distanceMeters!.toStringAsFixed(1)}m'
                                        : 'Set dist.',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1B4332),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    if (_manualPoints.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${_manualPoints.length} manual point(s) added',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _imageBytes = null;
                              _edges = [];
                              _manualPoints = [];
                              _error = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Upload Different Sketch',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showFinalizeSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4332),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Review & Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final List<DetectedEdge> edges;
  final List<ManualPoint> manualPoints;
  final Offset Function(Offset) toDisplay;

  _OverlayPainter({
    required this.edges,
    required this.manualPoints,
    required this.toDisplay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in edges.asMap().entries) {
      final index = entry.key;
      final e = entry.value;

      final p1 = toDisplay(e.p1);
      final p2 = toDisplay(e.p2);
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

      final color = e.selected
          ? const Color(0xFF52B788)
          : Colors.redAccent.withValues(alpha: 0.65);

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = color
          ..strokeWidth = e.selected ? 4 : 2
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(p1, 5, Paint()..color = color);
      canvas.drawCircle(p2, 5, Paint()..color = color);

      _drawBadge(
        canvas,
        'Edge ${index + 1}',
        Offset(mid.dx, mid.dy - 18),
        color,
      );

      if (e.distanceMeters != null) {
        _drawBadge(
          canvas,
          '${e.distanceMeters!.toStringAsFixed(1)}m',
          Offset(mid.dx, mid.dy + 18),
          color,
        );
      }
    }

    for (final m in manualPoints) {
      final p = toDisplay(m.pos);
      canvas.drawCircle(p, 6, Paint()..color = const Color(0xFF2196F3));
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawBadge(Canvas canvas, String text, Offset center, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingX = 6.0;
    const paddingY = 3.0;

    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + paddingX * 2,
      height: tp.height + paddingY * 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    tp.paint(canvas, Offset(rect.left + paddingX, rect.top + paddingY));
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => true;
}
