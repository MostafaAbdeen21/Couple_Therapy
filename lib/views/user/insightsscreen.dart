import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InsightsScreen extends StatelessWidget {
  final String userid;

  const InsightsScreen({super.key, required this.userid});

  @override
  Widget build(BuildContext context) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userid);
    final summariesRef = userRef.collection('summaries');

    return Scaffold(
      appBar: AppBar(title: const Text("Insights")),
      body: FutureBuilder(
        future: Future.wait([
          userRef.get(),
          summariesRef.orderBy('timestamp', descending: true).limit(7).get(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userDoc = snapshot.data![0] as DocumentSnapshot;
          final summaries = snapshot.data![1] as QuerySnapshot;

          final journalCount = userDoc['journalCount'] ?? 0;
          final sessionCount = userDoc['sessionCount'] ?? 0;

          // استخراج مشاعر الأيام الأخيرة
          final emotions = {
            'anger': <double>[],
            'stress': <double>[],
            'sadness': <double>[],
          };

          for (var doc in summaries.docs) {
            final data = doc.data() as Map<String, dynamic>;
            emotions['anger']!.add((data['anger'] ?? 0).toDouble());
            emotions['stress']!.add((data['stress'] ?? 0).toDouble());
            emotions['sadness']!.add((data['sadness'] ?? 0).toDouble());
          }

          // أحدث ملخص (لـ Pie Chart)
          final latestSummary = summaries.docs.isNotEmpty
              ? summaries.docs.first.data() as Map<String, dynamic>
              : null;

          final double latestAnger = latestSummary?['anger']?.toDouble() ?? 0;
          final double latestStress = latestSummary?['stress']?.toDouble() ?? 0;
          final double latestSadness = latestSummary?['sadness']?.toDouble() ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text("📈 Weekly Emotional Trends", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("Anger", Colors.red),
                    const SizedBox(width: 12),
                    _buildLegendItem("Stress", Colors.orange),
                    const SizedBox(width: 12),
                    _buildLegendItem("Sadness", Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 10,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) => Text("D${value.toInt() + 1}", style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: emotions.entries.map((e) {
                        return LineChartBarData(
                          isCurved: true,
                          spots: List.generate(e.value.length, (i) => FlSpot(i.toDouble(), e.value[i])),
                          dotData: FlDotData(show: false),
                          color: e.key == 'anger' ? Colors.red : e.key == 'stress' ? Colors.orange : Colors.blue,
                          barWidth: 3,
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Pie Chart section
                if (latestAnger + latestStress + latestSadness > 0) ...[
                  const SizedBox(height: 32),
                  Text("😶‍🌫️ Today's Emotional Distribution", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(
                            value: latestAnger,
                            color: Colors.red,
                            title: 'Anger',
                            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: latestStress,
                            color: Colors.orange,
                            title: 'Stress',
                            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          PieChartSectionData(
                            value: latestSadness,
                            color: Colors.blue,
                            title: 'Sadness',
                            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                Text("🗓️ Journals this month: $journalCount"),
                Text("🧑‍🤝‍🧑 Sessions attended: $sessionCount"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
