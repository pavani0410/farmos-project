import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/farm.dart';
import '../models/plot.dart';
import 'sketch_digitizer_screen.dart';

// ── colours ───────────────────────────────────────────────────────────────────
const _kColors = [
  Color(0xFF52B788),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
];
const _kFills = [
  Color(0x1A52B788),
  Color(0x1A2196F3),
  Color(0x1AFF9800),
  Color(0x1AE91E63),
  Color(0x1A9C27B0),
  Color(0x1A00BCD4),
];

// ── math helpers ──────────────────────────────────────────────────────────────
double _dist(Offset a, Offset b) =>
    sqrt(pow(a.dx - b.dx, 2) + pow(a.dy - b.dy, 2));

double _polyArea(List<Offset> pts) {
  double a = 0;
  for (int i = 0; i < pts.length; i++) {
    final j = (i + 1) % pts.length;
    a += pts[i].dx * pts[j].dy - pts[j].dx * pts[i].dy;
  }
  return a.abs() / 2;
}

Offset _nextPoint(Offset from, double angleDeg, double pixelDist) {
  final rad = angleDeg * pi / 180;
  return Offset(from.dx + pixelDist * cos(rad), from.dy + pixelDist * sin(rad));
}

// ── saved plot model ──────────────────────────────────────────────────────────
class _PlotData {
  final int id;
  final String name;
  final String soilType;
  final double areaAcres;
  final List<Offset> points;
  final List<double> edgeDistances;
  final String? digitizedDiagram;
  final Color color;
  final Color fill;
  _PlotData({
    required this.id,
    required this.name,
    required this.soilType,
    required this.areaAcres,
    required this.points,
    required this.edgeDistances,
    this.digitizedDiagram,
    required this.color,
    required this.fill,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN — scoped to one farm
// ══════════════════════════════════════════════════════════════════════════════
class PlotsScreen extends StatefulWidget {
  final Farm farm;
  const PlotsScreen({super.key, required this.farm});

  @override
  State<PlotsScreen> createState() => _PlotsScreenState();
}

class _PlotsScreenState extends State<PlotsScreen> {
  List<_PlotData> _plots = [];
  bool _loading = true;

  // drawing state
  List<Offset> _markers = [];
  List<double> _distances = [];
  bool _closed = false;
  List<Offset> _polygon = [];

  @override
  void initState() {
    super.initState();
    _loadPlots();
  }

  Future<void> _loadPlots() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPlots(widget.farm.id);
      setState(() {
        _plots = data.asMap().entries.map((e) {
          final p = Plot.fromJson(e.value);
          List<Offset> pts = [];
          try {
            final raw = jsonDecode(p.polygonPoints) as List;
            pts = raw
                .map(
                  (pt) => Offset(
                    (pt['x'] as num).toDouble(),
                    (pt['y'] as num).toDouble(),
                  ),
                )
                .toList();
          } catch (_) {}
          return _PlotData(
            id: p.id,
            name: p.name,
            soilType: p.soilType,
            areaAcres: p.areaAcres,
            points: pts,
            edgeDistances: _readEdgeDistances(p.digitizedDiagram, pts),
            digitizedDiagram: p.digitizedDiagram,
            color: _kColors[e.key % _kColors.length],
            fill: _kFills[e.key % _kFills.length],
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePlot(int plotId) async {
    await ApiService.deletePlot(widget.farm.id, plotId);
    await _loadPlots();
  }

  void _confirmDelete(_PlotData plot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plot'),
        content: Text('Delete "${plot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePlot(plot.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _decodeDigitizedDiagram(_PlotData plot) {
    final diagram = plot.digitizedDiagram;
    if (diagram == null || diagram.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(diagram);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  List<double> _readEdgeDistances(
    String? digitizedDiagram,
    List<Offset> points,
  ) {
    if (digitizedDiagram == null || digitizedDiagram.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(digitizedDiagram);
      if (decoded is! Map<String, dynamic>) return [];
      final raw = decoded['edgeDistances'];
      if (raw is List) {
        return raw
            .whereType<num>()
            .map((distance) => distance.toDouble())
            .toList();
      }

      final scale = (decoded['scaleMetersPerPixel'] as num?)?.toDouble();
      if (scale == null || scale <= 0 || points.length < 3) return [];
      return List.generate(points.length, (i) {
        final next = (i + 1) % points.length;
        return _dist(points[i], points[next]) * scale;
      });
    } catch (_) {
      return [];
    }
  }

  void _showPlotDiagram(_PlotData plot) {
    final diagram = _decodeDigitizedDiagram(plot);
    final imageBase64 = diagram?['imageBytesBase64'] as String?;
    final imageBytes = imageBase64 == null
        ? null
        : _tryDecodeBase64(imageBase64);
    final imageWidth = (diagram?['imageWidth'] as num?)?.toDouble();
    final imageHeight = (diagram?['imageHeight'] as num?)?.toDouble();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          plot.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
        content: SizedBox(
          width: 420,
          child: AspectRatio(
            aspectRatio:
                imageWidth != null &&
                    imageHeight != null &&
                    imageWidth > 0 &&
                    imageHeight > 0
                ? imageWidth / imageHeight
                : 1.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageBytes != null)
                      Image.memory(imageBytes, fit: BoxFit.fill),
                    CustomPaint(
                      painter: _SavedDiagramPainter(
                        points: plot.points,
                        edgeDistances: plot.edgeDistances,
                        showDistanceLabels: true,
                        color: plot.color,
                        fill: plot.fill,
                        sourceSize:
                            imageWidth != null &&
                                imageHeight != null &&
                                imageWidth > 0 &&
                                imageHeight > 0
                            ? Size(imageWidth, imageHeight)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Uint8List? _tryDecodeBase64(String value) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  // ── drawing logic ───────────────────────────────────────────────────────────
  void _onTapCanvas(Offset pos) {
    if (_closed) return;
    setState(() => _markers.add(pos));
    if (_markers.length > 1) {
      _askDistance(_markers.length - 2, _markers.length - 1);
    }
  }

  void _askDistance(int fromIdx, int toIdx) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('📏', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Point ${fromIdx + 1} → ${toIdx + 1}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4332),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the real distance between these two points:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1B4332)),
              decoration: InputDecoration(
                hintText: 'e.g. 50',
                suffixText: 'metres',
                filled: true,
                fillColor: const Color(0xFFF4F6F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1B4332)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _markers.removeLast());
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final d = double.tryParse(ctrl.text.trim());
              if (d == null || d <= 0) return;
              setState(() => _distances.add(d));
              Navigator.pop(ctx);
              _rebuildPolygon();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _rebuildPolygon() {
    if (_markers.length < 2 || _distances.isEmpty) return;
    final firstPixelLen = _dist(_markers[0], _markers[1]);
    if (firstPixelLen == 0) return;
    final pxPerM = firstPixelLen / _distances[0];

    final poly = <Offset>[_markers[0]];
    for (int i = 0; i < _distances.length; i++) {
      if (i + 1 >= _markers.length) break;
      final angle =
          atan2(
            _markers[i + 1].dy - _markers[i].dy,
            _markers[i + 1].dx - _markers[i].dx,
          ) *
          180 /
          pi;
      final pixelDist = _distances[i] * pxPerM;
      poly.add(_nextPoint(poly[i], angle, pixelDist));
    }
    setState(() => _polygon = poly);
  }

  void _closePolygon() {
    if (_markers.length < 3) return;
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Point ${_markers.length} → 1 (Closing)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Distance from last point back to first point:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 40',
                suffixText: 'metres',
                filled: true,
                fillColor: const Color(0xFFF4F6F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1B4332)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final d = double.tryParse(ctrl.text.trim());
              if (d == null || d <= 0) return;
              setState(() {
                _distances.add(d);
                _closed = true;
              });
              Navigator.pop(ctx);
              _rebuildPolygon();
              _showSaveDialog();
            },
            child: const Text(
              'Close & Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _buildManualDiagramJson(List<Map<String, double>> pointsJson) {
    return jsonEncode({
      'source': 'manual_mapper',
      'polygonPoints': pointsJson,
      'edgeDistances': _distances,
    });
  }

  void _showSaveDialog() {
    if (_polygon.length < 3) return;
    final pxArea = _polyArea(_polygon);
    final firstPixelLen = _markers.length >= 2
        ? _dist(_markers[0], _markers[1])
        : 1.0;
    final pxPerM = _distances.isNotEmpty ? firstPixelLen / _distances[0] : 1.0;
    final m2 = pxArea / (pxPerM * pxPerM);
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Save Plot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF52B788).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AreaChip(label: 'Area', value: '${m2.round()} m²'),
                    _AreaChip(label: 'Acres', value: acres.toStringAsFixed(3)),
                    _AreaChip(label: 'Points', value: '${_markers.length}'),
                    _AreaChip(
                      label: 'Perimeter',
                      value:
                          '${_distances.fold(0.0, (a, b) => a + b).round()}m',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1B4332)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Soil type',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
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
                  final pointsJson = _polygon
                      .map((p) => {'x': p.dx, 'y': p.dy})
                      .toList();
                  await ApiService.createPlot(widget.farm.id, {
                    'name': nameCtrl.text.trim(),
                    'soilType': soil,
                    'areaM2': m2,
                    'areaAcres': acres,
                    'polygonPoints': jsonEncode(pointsJson),
                    'digitizedDiagram': _buildManualDiagramJson(pointsJson),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {
                    _markers = [];
                    _distances = [];
                    _polygon = [];
                    _closed = false;
                  });
                  await _loadPlots();
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

  // ── build ────────────────────────────────────────────────────────────────────
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PLOT MAPPER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              widget.farm.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B4332),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B4332)),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // toolbar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          _ToolBtn(
                            label: 'Undo',
                            icon: Icons.undo_rounded,
                            enabled: _markers.isNotEmpty && !_closed,
                            onTap: () => setState(() {
                              if (_markers.isNotEmpty) _markers.removeLast();
                              if (_distances.isNotEmpty) {
                                _distances.removeLast();
                              }
                              _rebuildPolygon();
                            }),
                          ),
                          const SizedBox(width: 6),
                          _ToolBtn(
                            label: 'Clear',
                            icon: Icons.clear_rounded,
                            danger: true,
                            enabled: _markers.isNotEmpty,
                            onTap: () => setState(() {
                              _markers = [];
                              _distances = [];
                              _polygon = [];
                              _closed = false;
                            }),
                          ),
                          const SizedBox(width: 6),
                          _ToolBtn(
                            label: 'From Sketch',
                            icon: Icons.image_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => SketchDigitizerScreen(
                                    farmId: widget.farm.id,
                                    onSave:
                                        (
                                          name,
                                          soil,
                                          polygonPx,
                                          m2,
                                          acres,
                                          digitizedDiagram,
                                        ) async {
                                          final pointsJson = polygonPx
                                              .map(
                                                (p) => {'x': p.dx, 'y': p.dy},
                                              )
                                              .toList();
                                          await ApiService.createPlot(
                                            widget.farm.id,
                                            {
                                              'name': name,
                                              'soilType': soil,
                                              'areaM2': m2,
                                              'areaAcres': acres,
                                              'polygonPoints': jsonEncode(
                                                pointsJson,
                                              ),
                                              'digitizedDiagram':
                                                  digitizedDiagram,
                                            },
                                          );
                                          await _loadPlots();
                                        },
                                  ),
                                ),
                              );
                            },
                          ),
                          const Spacer(),
                          if (_markers.length >= 3 && !_closed)
                            GestureDetector(
                              onTap: _closePolygon,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4332),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Close & Save',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // canvas
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 340,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GestureDetector(
                            onTapDown: (d) => _onTapCanvas(d.localPosition),
                            child: CustomPaint(
                              painter: _MarkerPainter(
                                markers: _markers,
                                polygon: _polygon,
                                distances: _distances,
                                closed: _closed,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // hint
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF52B788,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _markers.isEmpty
                                    ? 'Tap on the canvas to place your first marker'
                                    : _closed
                                    ? 'Plot closed — scroll down to see saved plots'
                                    : _markers.length < 3
                                    ? 'Place ${3 - _markers.length} more point(s), then you can close the shape'
                                    : 'Tap "Close & Save" when done, or place more points',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // saved plots
                    if (_plots.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Saved Plots',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1B4332,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_plots.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1B4332),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 132,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _plots.length,
                          itemBuilder: (ctx, i) {
                            final plot = _plots[i];
                            return GestureDetector(
                              onTap: () => _showPlotDiagram(plot),
                              child: Container(
                                width: 170,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: plot.color,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            plot.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1B4332),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _confirmDelete(plot),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: double.infinity,
                                          color: const Color(0xFFF4F6F3),
                                          child: CustomPaint(
                                            painter: _SavedDiagramPainter(
                                              points: plot.points,
                                              edgeDistances: const [],
                                              showDistanceLabels: false,
                                              color: plot.color,
                                              fill: plot.fill,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            plot.soilType,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${plot.areaAcres.toStringAsFixed(2)} ac',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: plot.color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 40,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No plots yet for ${widget.farm.name}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── canvas painter ────────────────────────────────────────────────────────────
class _SavedDiagramPainter extends CustomPainter {
  final List<Offset> points;
  final List<double> edgeDistances;
  final bool showDistanceLabels;
  final Color color;
  final Color fill;
  final Size? sourceSize;

  _SavedDiagramPainter({
    required this.points,
    required this.edgeDistances,
    required this.showDistanceLabels,
    required this.color,
    required this.fill,
    this.sourceSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 3) return;

    final displayPoints = sourceSize == null
        ? _fitPointsToSize(size)
        : points
              .map(
                (p) => Offset(
                  p.dx * size.width / sourceSize!.width,
                  p.dy * size.height / sourceSize!.height,
                ),
              )
              .toList();

    final path = Path()..moveTo(displayPoints[0].dx, displayPoints[0].dy);
    for (final p in displayPoints.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    for (final p in displayPoints) {
      canvas.drawCircle(p, 3.5, Paint()..color = color);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }

    if (showDistanceLabels && edgeDistances.isNotEmpty) {
      for (int i = 0; i < displayPoints.length; i++) {
        if (i >= edgeDistances.length) break;
        final next = (i + 1) % displayPoints.length;
        final mid = Offset(
          (displayPoints[i].dx + displayPoints[next].dx) / 2,
          (displayPoints[i].dy + displayPoints[next].dy) / 2,
        );
        _drawDistanceLabel(
          canvas,
          '${edgeDistances[i].toStringAsFixed(1)} m',
          mid,
        );
      }
    }
  }

  void _drawDistanceLabel(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF1B4332),
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
      Paint()..color = Colors.white.withValues(alpha: 0.92),
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

  List<Offset> _fitPointsToSize(Size size) {
    final minX = points.map((p) => p.dx).reduce(min);
    final maxX = points.map((p) => p.dx).reduce(max);
    final minY = points.map((p) => p.dy).reduce(min);
    final maxY = points.map((p) => p.dy).reduce(max);
    final width = max(maxX - minX, 1);
    final height = max(maxY - minY, 1);
    final scale = min((size.width - 18) / width, (size.height - 18) / height);
    final drawnW = width * scale;
    final drawnH = height * scale;
    final dx = (size.width - drawnW) / 2;
    final dy = (size.height - drawnH) / 2;

    return points
        .map(
          (p) => Offset(dx + (p.dx - minX) * scale, dy + (p.dy - minY) * scale),
        )
        .toList();
  }

  @override
  bool shouldRepaint(_SavedDiagramPainter old) => true;
}

class _MarkerPainter extends CustomPainter {
  final List<Offset> markers;
  final List<Offset> polygon;
  final List<double> distances;
  final bool closed;

  _MarkerPainter({
    required this.markers,
    required this.polygon,
    required this.distances,
    required this.closed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (polygon.length >= 3) {
      final path = Path()..moveTo(polygon[0].dx, polygon[0].dy);
      for (final p in polygon.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFF52B788).withValues(alpha: 0.15),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF52B788)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    for (int i = 0; i < markers.length; i++) {
      final p = markers[i];
      if (i < markers.length - 1) {
        canvas.drawLine(
          p,
          markers[i + 1],
          Paint()
            ..color = const Color(0xFF1B4332).withValues(alpha: 0.3)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      }
      if (closed && i == markers.length - 1 && markers.length > 2) {
        canvas.drawLine(
          p,
          markers[0],
          Paint()
            ..color = const Color(0xFF1B4332).withValues(alpha: 0.3)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      }
      canvas.drawCircle(p, 8, Paint()..color = const Color(0xFF1B4332));
      canvas.drawCircle(p, 6, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = i == 0 ? const Color(0xFF52B788) : const Color(0xFF1B4332),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));

      if (i < distances.length && i < markers.length - 1) {
        final mid = Offset(
          (markers[i].dx + markers[i + 1].dx) / 2,
          (markers[i].dy + markers[i + 1].dy) / 2,
        );
        _drawLabel(canvas, '${distances[i].round()}m', mid);
      }
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Color(0xFF1B4332),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          background: Paint()..color = Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2 - 10),
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => true;
}

// ── small helper widgets ──────────────────────────────────────────────────────
class _AreaChip extends StatelessWidget {
  final String label;
  final String value;
  const _AreaChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool danger;
  final VoidCallback onTap;
  const _ToolBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.danger = false,
  });
  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade400 : Colors.grey.shade600;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: danger ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: danger ? Colors.red.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: enabled ? color : Colors.grey.shade300),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: enabled ? color : Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
