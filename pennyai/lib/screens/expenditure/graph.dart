import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  const ExpenseAnalysisScreen({Key? key}) : super(key: key);

  @override
  _ExpenseAnalysisScreenState createState() => _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;

  // Category expense totals
  Map<String, double> _categoryTotals = {};

  // Daily expense totals
  Map<DateTime, double> _dailyTotals = {};

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      final response = await Supabase.instance.client
          .from('expenses')
          .select()
          .order('date');

      setState(() {
        _expenses = List<Map<String, dynamic>>.from(response);
        _calculateExpenseTotals();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching expenses: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _calculateExpenseTotals() {
    // Reset totals
    _categoryTotals = {};
    _dailyTotals = {};

    for (var expense in _expenses) {
      // Category totals
      final category = expense['category'];
      final amount = (expense['amount'] as num).toDouble();
      _categoryTotals[category] =
          (_categoryTotals[category] ?? 0) + amount;

      // Daily totals
      final date = DateTime.parse(expense['date']);
      final dateWithoutTime = DateTime(date.year, date.month, date.day);
      _dailyTotals[dateWithoutTime] =
          (_dailyTotals[dateWithoutTime] ?? 0) + amount;
    }
  }

  List<PieChartSectionData> _generateCategoryPieCharts() {
    final colors = [
      Colors.deepPurple,
      Colors.purple,
      Colors.purpleAccent,
      Colors.deepPurpleAccent,
      Colors.indigo,
    ];

    return _categoryTotals.entries.map((entry) {
      final index = _categoryTotals.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${entry.key}\n₹${entry.value.toStringAsFixed(2)}',
        radius: 100,
        titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white
        ),
      );
    }).toList();
  }

  List<FlSpot> _generateDailyLineChartSpots() {
    // Sort dates to ensure chronological order
    final sortedDates = _dailyTotals.keys.toList()..sort();

    return sortedDates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final amount = _dailyTotals[date]!;

      return FlSpot(index.toDouble(), amount);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Analysis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Times New Roman',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
          ? const Center(child: Text('No expenses found'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Expenses by Category'),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _generateCategoryPieCharts(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Daily Expense Trend'),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 100,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.deepPurple.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.deepPurple.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          interval: 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final sortedDates = _dailyTotals.keys.toList()..sort();
                            if (value.toInt() < sortedDates.length) {
                              return Text(
                                DateFormat('dd/MM').format(sortedDates[value.toInt()]),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.deepPurple,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 200,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              meta.formattedValue,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.deepPurple,
                              ),
                            );
                          },
                          reservedSize: 42,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateDailyLineChartSpots(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade400,
                            Colors.deepPurple.shade700,
                          ],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.deepPurple.shade700,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade100.withOpacity(0.5),
                              Colors.deepPurple.shade400.withOpacity(0.2),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTotalExpensesSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildTotalExpensesSummary() {
    final totalExpenses = _expenses.fold(
        0.0,
            (previous, expense) => previous + (expense['amount'] as num).toDouble()
    );

    return Card(
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              '₹${totalExpenses.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}