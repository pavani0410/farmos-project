import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/farm.dart';
import 'plots_screen.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  List<Farm> farms = [];
  bool loading = true;
  bool showForm = false;

  final nameController = TextEditingController();
  final acresController = TextEditingController();
  final locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFarms();
  }

  Future<void> fetchFarms() async {
    try {
      final data = await ApiService.getFarms();
      setState(() {
        farms = data.map((f) => Farm.fromJson(f)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> createFarm() async {
    if (nameController.text.isEmpty ||
        acresController.text.isEmpty ||
        locationController.text.isEmpty) return;

    try {
      await ApiService.createFarm({
        'name': nameController.text,
        'acres': double.parse(acresController.text),
        'location': locationController.text,
      });
      nameController.clear();
      acresController.clear();
      locationController.clear();
      setState(() => showForm = false);
      fetchFarms();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> deleteFarm(int id) async {
    try {
      await ApiService.deleteFarm(id);
      fetchFarms();
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MY FARMS',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500, letterSpacing: 1.2,
                        ),
                      ),
                      const Text('Farm Management',
                        style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => showForm = !showForm),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4332),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // add farm form
            if (showForm)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Farm',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FormField(controller: nameController, label: 'Farm Name', hint: 'e.g. My Avocado Farm'),
                    const SizedBox(height: 10),
                    _FormField(controller: acresController, label: 'Total Acres', hint: 'e.g. 40', isNumber: true),
                    const SizedBox(height: 10),
                    _FormField(controller: locationController, label: 'Location', hint: 'e.g. Karnataka'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: createFarm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4332),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('Save Farm',
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
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => showForm = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Cancel',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (showForm) const SizedBox(height: 16),

            // farms list
            Expanded(
              child: loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332)))
                : farms.isEmpty
                  ? _EmptyState(onAdd: () => setState(() => showForm = true))
                  : RefreshIndicator(
                      color: const Color(0xFF1B4332),
                      onRefresh: fetchFarms,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: farms.length,
                        itemBuilder: (context, index) {
                          final farm = farms[index];
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => PlotsScreen(farm: farm),
                                ),
                              );
                            },
                            child: _FarmCard(
                              farm: farm,
                              onDelete: () => _confirmDelete(context, farm),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Farm farm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Farm'),
        content: Text('Are you sure you want to delete "${farm.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteFarm(farm.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final VoidCallback onDelete;
  const _FarmCard({required this.farm, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final initials = farm.name
      .split(' ').take(2)
      .map((w) => w[0].toUpperCase()).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B4332).withOpacity(0.08),
            ),
            child: Center(
              child: Text(initials,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farm.name,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text(farm.location,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.crop_square_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text('${farm.acres} ac',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (val) {
              if (val == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B4332).withOpacity(0.06),
            ),
            child: Icon(Icons.agriculture_outlined,
              size: 36, color: const Color(0xFF1B4332).withOpacity(0.3)),
          ),
          const SizedBox(height: 16),
          const Text('No farms yet',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 6),
          Text('Tap + to add your first farm',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Add Farm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isNumber;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1B4332)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF4F6F3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1B4332)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}