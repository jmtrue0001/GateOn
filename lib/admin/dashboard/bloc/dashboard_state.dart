part of 'dashboard_bloc.dart';

@CopyWith()
class DashboardState extends CommonState {
  const DashboardState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.query,
    this.allCount = 0,
    this.todayCount = 0,
    this.disableCount = 0,
    this.disableTotalCount = 0,
    this.abnornalCount = 0,
    this.chartType = ChartType.day,
    this.year,
    this.month,
    this.chartData = const [],
  });

  final int allCount;
  final int todayCount;
  final int disableCount;
  final int disableTotalCount;
  final int abnornalCount;
  final ChartType chartType;
  final int? year;
  final int? month;
  final List<ChartData> chartData;

  @override
  List<Object?> get props => [...super.props, allCount, todayCount, chartData,disableTotalCount ,disableCount, chartType, year, month, abnornalCount];
}

