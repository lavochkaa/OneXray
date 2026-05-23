import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:onexray/core/db/database/database.dart';

class OutboundSelectState {
  final List<CoreConfigData> configs;

  const OutboundSelectState({required this.configs});

  factory OutboundSelectState.initial() =>
      const OutboundSelectState(configs: []);
}

class OutboundSelectController extends Cubit<OutboundSelectState> {
  OutboundSelectController() : super(OutboundSelectState.initial()) {
    _queryConfigs();
  }

  Future<void> _queryConfigs() async {
    final db = AppDatabase();
    final configs = await db.coreConfigDao.allOutboundRowsWithData;
    emit(OutboundSelectState(configs: configs));
  }

  void select(BuildContext context, CoreConfigData config) {
    context.pop<CoreConfigData>(config);
  }
}
