import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../enum/enums.dart';

abstract class CommonEvent<T> extends Equatable {
  const CommonEvent();

  @override
  List<Object> get props => [];
}

class Initial<T> extends CommonEvent<T> {
  const Initial({this.id = '', this.data});

  final String id;
  final dynamic data;
}

class Detail<T> extends CommonEvent<T> {
  const Detail({this.id = ''});

  final String id;
}

class Add<T> extends CommonEvent<T> {
  const Add(this.data);

  final Map<String, dynamic> data;
}

class Edit<T> extends CommonEvent<T> {
  const Edit(this.id, this.data);

  final String? id;
  final Map<String, dynamic> data;
}

class Submit<T> extends CommonEvent<T> {
  const Submit(this.data, {this.context});

  final Map<String, dynamic> data;
  final BuildContext? context;
}

class Delete<T> extends CommonEvent {
  const Delete({this.id});

  final String? id;
}

class Paginate<T> extends CommonEvent<T> {
  const Paginate({this.id, this.page, this.query, this.filterType, this.orderType});

  final String? id;
  final int? page;
  final String? query;
  final FilterType? filterType;
  final OrderType? orderType;
}

class Search<T> extends CommonEvent<T> {
  const Search({this.id = '', this.query = ''});

  final String id;
  final String query;
}

class ChangeIndex<T> extends CommonEvent<T> {
  const ChangeIndex(this.index);

  final int index;
}

class Error<T> extends CommonEvent<T> {
  const Error({required this.errorMessage, this.commonStatus, this.uploadStatus});

  final String errorMessage;
  final CommonStatus? commonStatus;
  final UploadStatus? uploadStatus;
}
