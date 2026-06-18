import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/farm.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Farm> farms = [];
  bool loading = true;
  double totalAcres = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final data = await ApiService.getFarms();
      final farmList = data.map((f) => Farm.fromJson(f)).toList();
      setState(() {
        farms = farmList;
        totalAcres = farmList.fold(0, (sum, f) => sum + f.acres);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F3),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B4332)),
              )
            : RefreshIndicator(
                color: const Color(0xFF1B4332),
                onRefresh: fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1B4332),
                                ),
                                child: const Center(
                                  child: Text(
                                    'RV',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FarmOS · Dashboard',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const Text(
                                    'Hi, Pavani',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B4332),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // overview label
                      Text(
                        'OVERVIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // stat cards row
                      Row(
                        children: [
                          // total area card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4332),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TOTAL AREA',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Icon(
                                        Icons.trending_up_rounded,
                                        size: 16,
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              '${totalAcres.toStringAsFixed(0)} ',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'acres',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Across ${farms.length} active farm${farms.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // crop health card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'CROP HEALTH',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Good',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B4332),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // health bar
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Expanded(
                                        child: Container(
                                          height: 4,
                                          margin: const EdgeInsets.only(
                                            right: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: i < 3
                                                ? const Color(0xFF52B788)
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${farms.length} of ${farms.length} zones active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // my farms section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MY FARMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF52B788),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // farms list
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: farms.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    'No farms yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: farms.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final farm = entry.value;
                                  final initials = farm.name
                                      .split(' ')
                                      .take(2)
                                      .map((w) => w[0].toUpperCase())
                                      .join();
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(
                                                  0xFF1B4332,
                                                ).withValues(alpha: 0.08),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1B4332),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    farm.name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF1B4332),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${farm.acres} ac · ${farm.location}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: Colors.grey.shade300,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < farms.length - 1)
                                        Divider(
                                          height: 1,
                                          color: Colors.grey.shade100,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // add new farm button
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4332),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Add New Farm',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_outward_rounded,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // plot mapping section label
                      Text(
                        'PLOT MAPPING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // plot chips
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
