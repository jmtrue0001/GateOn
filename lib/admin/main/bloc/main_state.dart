part of 'main_bloc.dart';

@CopyWith()
class MainState extends CommonState {
  const MainState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page = 0,
    super.query,
    this.enterpriseInfo,
  });


  final EnterpriseInfo? enterpriseInfo;

  @override
  List<Object?> get props => [...super.props, enterpriseInfo];
}
