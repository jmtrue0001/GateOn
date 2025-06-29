part of 'dashboard_bloc.dart';

class DashboardEvent extends CommonEvent {
  const DashboardEvent();
}

class ChangeChartType extends DashboardEvent {
  const ChangeChartType(this.chartType);

  final ChartType chartType;
}

class ChangeDate extends DashboardEvent {
  const ChangeDate(this.dateTime);

  final DateTime dateTime;
}

class ChangeYear extends DashboardEvent {
  const ChangeYear(this.dateTime);

  final DateTime dateTime;
}