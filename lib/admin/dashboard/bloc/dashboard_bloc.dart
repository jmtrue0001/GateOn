import 'package:TPASS/admin/dashboard/repository/dashboard_repository.dart';
import 'package:TPASS/core/core.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';
part 'generated/dashboard_bloc.g.dart';

class DashboardBloc extends Bloc<CommonEvent, DashboardState> {
  DashboardBloc() : super(const DashboardState()) {
    on<Initial>(_onInitial);
    on<ChangeChartType>(_onChangeChartType);
    on<ChangeDate>(_onChangeDate);
  }

  _onInitial(Initial event, Emitter<DashboardState> emit) async {
    await DashboardApi.to.countAllVisitors().then((value) => emit(state.copyWith(allCount: value.data?.cnt)));
    await DashboardApi.to.countTodayVisitors().then((value) => emit(state.copyWith(todayCount: value.data?.cnt)));
    await DashboardApi.to.countDisableVisitors().then((value) => emit(state.copyWith(disableCount: value.data?.cnt)));
    await DashboardApi.to.countDayVisitors(dateDataParser(date: DateTime.now())).then((value) {
      List<ChartData> chartData = (value.data ?? []).asMap().entries.map((element) => ChartData(month: element.value.visitNumber.toString(), day: element.value.visitNumber.toString(), number: element.value.visitorCount)).toList();
      int countDay = 0;
      value.data?.forEach((element) {
        countDay += element.visitorCount ?? 0;
      });
      logger.d(countDay);
      logger.d(chartData.toList());
      return emit(state.copyWith(chartData: chartData, allCount: countDay));
    });
  }

  _onChangeChartType(ChangeChartType event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(chartType: event.chartType, month: DateTime.now().month, year: DateTime.now().year));
    switch (event.chartType) {
      case ChartType.month:
        await DashboardApi.to.countMonthVisitors(dateDataParser(date: DateTime.now(), format: 'yyyy')).then((value) {
          List<ChartData> chartData = (value.data ?? []).asMap().entries.map((element) => ChartData(month: element.value.visitNumber.toString(), day: element.value.visitNumber.toString(), number: element.value.visitorCount)).toList();
          int countMonth = 0;
          value.data?.forEach((element) {
            countMonth += element.visitorCount ?? 0;
          });

          return emit(state.copyWith(chartData: chartData,allCount: countMonth));
        });
        break;
      case ChartType.day:
        await DashboardApi.to.countDayVisitors(dateDataParser(date: DateTime.now())).then((value) {
          List<ChartData> chartData = (value.data ?? []).asMap().entries.map((element) => ChartData(month: element.value.visitNumber.toString(), day: element.value.visitNumber.toString(), number: element.value.visitorCount)).toList();
          int countDay = 0;
          value.data?.forEach((element) {
            countDay += element.visitorCount ?? 0;
          });
          logger.d(countDay);
          return emit(state.copyWith(chartData: chartData, allCount: countDay));
        });
      default:
    }
  }

  _onChangeDate(ChangeDate event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(month: event.dateTime.month, year: event.dateTime.year));
    switch (state.chartType) {
      case ChartType.month:
        await DashboardApi.to.countMonthVisitors(dateDataParser(date: event.dateTime, format: 'yyyy')).then((value) {
          List<ChartData> chartData = (value.data ?? []).asMap().entries.map((element) => ChartData(month: element.value.visitNumber.toString(), day: element.value.visitNumber.toString(), number: element.value.visitorCount)).toList();
          int countMonth = 0;
          value.data?.forEach((element) {
            countMonth += element.visitorCount ?? 0;
          });
          return emit(state.copyWith(chartData: chartData, allCount: countMonth));
        });
      case ChartType.day:
        await DashboardApi.to.countDayVisitors(dateDataParser(date: event.dateTime)).then((value) {
          List<ChartData> chartData = (value.data ?? []).asMap().entries.map((element) => ChartData(month: element.value.visitNumber.toString(), day: element.value.visitNumber.toString(), number: element.value.visitorCount)).toList();
          int countDay = 0;
          value.data?.forEach((element) {
            countDay += element.visitorCount ?? 0;
          });
          return emit(state.copyWith(chartData: chartData, allCount: countDay));
        });
        break;
      default:
        break;
    }
  }
}
