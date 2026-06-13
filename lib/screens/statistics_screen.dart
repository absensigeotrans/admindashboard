import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/timezone_utils.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(end);

      final data = await _supabase
          .from('attendance')
          .select()
          .eq('user_id', user.id)
          .gte('check_in_time', startStr)
          .lte('check_in_time', endStr)
          .order('check_in_time', ascending: true);

      if (mounted) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
    _fetchData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
    _fetchData();
  }

  int get _total => _records.length;
  int get _present => _records.where((r) => r['status'] == 'present').length;
  int get _late => _records.where((r) => r['status'] == 'late').length;
  int get _outside => _records.where((r) => r['status'] == 'outside_radius').length;
  double get _rate => _total > 0 ? (_present + _late) / _total * 100 : 0;

  Map<String, Map<String, int>> get _dailyStats {
    final map = <String, Map<String, int>>{};
    for (final r in _records) {
      final date = wibDateKey(r['check_in_time'] as String);
      map.putIfAbsent(date, () => {'present': 0, 'late': 0, 'outside': 0});
      final status = r['status'] as String? ?? 'present';
      if (map[date]!.containsKey(status)) {
        map[date]![status] = map[date]![status]! + 1;
      }
    }
    return map;
  }

  List<Map<String, dynamic>> get _dailyChartData {
    final stats = _dailyStats;
    final days = <Map<String, dynamic>>[];
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    for (int d = 1; d <= daysInMonth; d++) {
      final dateStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final dayStats = stats[dateStr];
      days.add({
        'day': d,
        'present': dayStats?['present'] ?? 0,
        'late': dayStats?['late'] ?? 0,
        'outside': dayStats?['outside'] ?? 0,
      });
    }
    return days;
  }

  Widget _buildSummaryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryTile(label: 'Total', value: '$_total', icon: Icons.receipt_long, color: Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryTile(label: 'Present', value: '$_present', icon: Icons.check_circle, color: Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryTile(label: 'Late', value: '$_late', icon: Icons.warning, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SummaryTile(label: 'Outside', value: '$_outside', icon: Icons.cancel, color: Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryTile(label: 'Rate', value: '${_rate.toStringAsFixed(1)}%', icon: Icons.trending_up, color: Colors.teal)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryTile(label: 'Absent', value: '${_total > 0 ? (_total - _present - _late) : 0}', icon: Icons.block, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final data = _dailyChartData;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Per-day breakdown for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? const Center(child: Text('No data', style: TextStyle(color: Colors.grey)))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (data.map((d) => (d['present'] as int) + (d['late'] as int) + (d['outside'] as int)).reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 5,
                              getTitlesWidget: (v, _) {
                                if (v.toInt() % 5 != 0) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('${v.toInt()}', style: const TextStyle(fontSize: 9)),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                        borderData: FlBorderData(show: false),
                        barGroups: data.map((d) {
                          return BarChartGroupData(x: d['day'] as int, barRods: [
                            BarChartRodData(
                              toY: (d['present'] as int).toDouble(),
                              color: Colors.green,
                              width: 8,
                            ),
                            BarChartRodData(
                              toY: (d['late'] as int).toDouble(),
                              color: Colors.orange,
                              width: 8,
                            ),
                            BarChartRodData(
                              toY: (d['outside'] as int).toDouble(),
                              color: Colors.red,
                              width: 8,
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: Colors.green, label: 'Present'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.orange, label: 'Late'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.red, label: 'Outside'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final hasData = _total > 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(DateFormat('MMMM yyyy').format(_selectedMonth),
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: !hasData
                  ? const Center(child: Text('No data', style: TextStyle(color: Colors.grey)))
                  : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          if (_present > 0)
                            PieChartSectionData(value: _present.toDouble(), title: '$_present', color: Colors.green, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          if (_late > 0)
                            PieChartSectionData(value: _late.toDouble(), title: '$_late', color: Colors.orange, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          if (_outside > 0)
                            PieChartSectionData(value: _outside.toDouble(), title: '$_outside', color: Colors.red, radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: Colors.green, label: 'Present'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.orange, label: 'Late'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.red, label: 'Outside'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLateLineChart() {
    final data = _dailyChartData.where((d) => (d['late'] as int) > 0).toList();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Late Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Daily late count for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: data.isEmpty
                  ? const Center(child: Text('No late records', style: TextStyle(color: Colors.grey)))
                  : LineChart(
                      LineChartData(
                        minX: data.first['day'].toDouble(),
                        maxX: data.last['day'].toDouble(),
                        lineTouchData: LineTouchData(enabled: true),
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (v, _) {
                              if (v.toInt() % 5 != 0 && data.length > 10) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${v.toInt()}', style: const TextStyle(fontSize: 9)),
                              );
                            }),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: data.map((d) => FlSpot((d['day'] as int).toDouble(), (d['late'] as int).toDouble())).toList(),
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: 2,
                            dotData: FlDotData(show: true, getDotPainter: (_, _, _, _) => FlDotCirclePainter(radius: 3, color: Colors.orange, strokeWidth: 0)),
                            belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF005494),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF005494),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: _prevMonth,
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryGrid(),
                  const SizedBox(height: 8),
                  _buildBarChart(),
                  _buildPieChart(),
                  _buildLateLineChart(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
