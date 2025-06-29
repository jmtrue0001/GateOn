part of 'permission_bloc.dart';

class PermissionEvent extends CommonEvent {
  const PermissionEvent();
}

class AgreeTerm extends PermissionEvent {
  const AgreeTerm(this.agree, this.type);

  final bool agree;
  final TermType type;
}

class AgreeAll extends PermissionEvent {}
