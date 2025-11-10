import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/core.dart';

class ChartDataWidget extends StatelessWidget {
  const ChartDataWidget({Key? key, this.data = const [], this.year, this.title = '', this.lineOne = false, this.chartType = ChartType.day, this.month, this.onDatePick, this.onChartTypePick}) : super(key: key);

  final List<ChartData> data;
  final int? year;
  final int? month;
  final Function(DateTime)? onDatePick;
  final Function(ChartType)? onChartTypePick;
  final String title;
  final bool lineOne;
  final ChartType chartType;

  @override
  Widget build(BuildContext context) {
    logger.d(data.last.day);
    logger.d(data.last.total);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: dataTypeWidget(context)),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('단위(명)'),
          ),
          const SizedBox(height: 16),
          if (data.isNotEmpty) Expanded(child: chartWidget(data, context))
        ],
      ),
    );
  }

  Widget chartWidget(List<ChartData> model, BuildContext context) {
    return barChart(
        model
            .asMap()
            .entries
            .map((e) => BarChartGroupData(x: int.parse(e.value.month ?? '1'), barRods: [
                  BarChartRodData(
                    width: 10,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                    toY: (e.value.number ?? 0).toDouble(),
                    color: const Color(0xff6FCF97),
                    rodStackItems: [],
                  ),
                ]))
            .toList(),
        context,
        chartType);
  }

  List<Widget> dataTypeWidget(BuildContext context) {
    return [
      Text(title, style: textTheme(context).krBody2),
      const SizedBox(width: 24),
      const SizedBox(width: 16),
      const Spacer(),
      TextButton(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xffEDF1F6), width: 1)),
          child: Row(
            children: [
              Text(
                '$year',
                style: textTheme(context).krSubtext2,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xffAAB0B6))
            ],
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: SizedBox(
                  width: 500,
                  height: 320,
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.5,
                          ),
                          children: [
                            for (int i = 2010; i <= DateTime.now().year; i++)
                              Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: i == month ? blue1 : null),
                                child: TextButton(
                                    onPressed: () {
                                      if (onDatePick != null) {
                                        onDatePick!(DateTime.parse('$i-${month.toString().padLeft(2, '0')}-01'));
                                      }
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      '$i년',
                                      style: textTheme(context).krBody1.copyWith(color: i == month ? white : null),
                                    )),
                              )
                          ],
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(top: 16, bottom: 8),
                        child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('취소')),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      if (chartType == ChartType.day)
        TextButton(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: const Color(0xffEDF1F6), width: 1)),
            child: Row(
              children: [
                Text(
                  '$month',
                  style: textTheme(context).krSubtext2,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xffAAB0B6))
              ],
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: SizedBox(
                    width: 500,
                    height: 320,
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.5,
                            ),
                            children: [
                              for (int i = 1; i < 13; i++)
                                Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: i == month ? blue1 : null),
                                  child: TextButton(
                                      onPressed: () {
                                        if (onDatePick != null) {
                                          onDatePick!(DateTime.parse('$year-${i.toString().padLeft(2, '0')}-01'));
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        '$i월',
                                        style: textTheme(context).krBody1.copyWith(color: i == month ? white : null),
                                      )),
                                )
                            ],
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(top: 16, bottom: 8),
                          child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('취소')),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      TextButton(
          onPressed: () {
            if (onChartTypePick != null) {
              onChartTypePick!(ChartType.day);
            }
          },
          child: Text('일 별', style: textTheme(context).krBody2.copyWith(color: chartType == ChartType.day ? Colors.black : const Color(0xffAAB0B6)))),
      TextButton(
          onPressed: () {
            if (onChartTypePick != null) {
              onChartTypePick!(ChartType.month);
            }
          },
          child: Text('월 별', style: textTheme(context).krBody2.copyWith(color: chartType == ChartType.month ? Colors.black : const Color(0xffAAB0B6)))),
    ];
  }

  Widget barChart(List<BarChartGroupData>? barGroups, BuildContext context, ChartType chartType) {

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (data, meta) {
                  return Container(margin: const EdgeInsets.only(top: 16), child: Text("$data", style: textTheme(context).krSubtext2));
                }),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 64,
              getTitlesWidget: (data, meta) {

                return data == meta.min
                    ? Container(margin: const EdgeInsets.only(right: 8), child: Text("$year년", style: textTheme(context).krSubtext2))
                    : data == meta.max
                        ? Container()
                        : Container(margin: const EdgeInsets.only(right: 8), child: Text("${data.toInt()}명", style: textTheme(context).krSubtext2));
              },
            ),
          ),
        ),
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (data) {
              return FlLine(strokeWidth: 0.7, color: gray5);
            }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
      swapAnimationCurve: Curves.easeInOut,
    );
  }

  Widget lineChart(List<LineChartBarData> lines, BuildContext context, ChartType chartType) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 56,
                getTitlesWidget: (data, meta) {
                  return Container(margin: const EdgeInsets.only(top: 16), child: Text("$data${chartType == ChartType.month ? '월' : '일'}", style: textTheme(context).krSubtext2));
                }),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: lineOne ? 10000000 : 100,
              reservedSize: 64,
              getTitlesWidget: (data, meta) {
                return data == meta.min
                    ? Container(margin: const EdgeInsets.only(right: 8), child: Text("$year년", style: textTheme(context).krSubtext2))
                    : data == meta.max
                        ? Container()
                        : Container(margin: const EdgeInsets.only(right: 8), child: Text("${data / (lineOne ? 10000 : 1)}${lineOne ? '(만)원' : '명'}", style: textTheme(context).krSubtext2));
                // : Container();
              },
            ),
          ),
        ),
        lineBarsData: lines,
        borderData: FlBorderData(show: false),
        maxY: double.parse(((data.last.accrue ?? 0) * 1.2).toStringAsFixed(0)),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (data) {
            return FlLine(strokeWidth: 1, color: gray5);
          },
          getDrawingVerticalLine: (data) {
            return FlLine(strokeWidth: 1, color: gray5);
          },
        ),
      ),
    );
  }

  Widget pieChart(List<PieChartSectionData>? sections, BuildContext context) {
    return PieChart(
      PieChartData(
        borderData: FlBorderData(show: false),
        sections: sections,
        sectionsSpace: 0,
        centerSpaceRadius: 50,
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
      swapAnimationCurve: Curves.easeInOut,
    );
  }
}
