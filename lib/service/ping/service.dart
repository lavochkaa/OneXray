import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/service/event_bus/service.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/db/database/enum.dart';
import 'package:onexray/core/tools/empty.dart';
import 'package:onexray/service/localizations/service.dart';
import 'package:onexray/service/ping/state.dart';
import 'package:onexray/service/xray/outbound/state.dart';
import 'package:onexray/service/xray/outbound/state_reader.dart';

class PingService {
  static final PingService _singleton = PingService._internal();

  factory PingService() => _singleton;

  PingService._internal();

  Future<void> pingOutboundConfigs(int subId) async {
    final eventBus = AppEventBus.instance;
    eventBus.updatePinging(true);
    final db = AppDatabase();
    final rows = await db.coreConfigDao.allOutboundRowsWithDataBySubId(subId);
    await _pingConfigs(db, rows);
    eventBus.updatePinging(false);
  }

  Future<int> _pingOutbound(CoreConfigData row, PingState pingState) async {
    if (EmptyTool.checkString(row.data)) {
      final outbound = OutboundState();
      outbound.readFromDbData(row);
      return _tcpPing(outbound.address, outbound.port, pingState);
    }
    return PingDelayConstants.unknown;
  }

  Future<void> pingRawConfigs(int subId) async {
    // Raw JSON configs don't have extractable host/port — skip pinging
  }

  Future<int> _tcpPing(
    String address,
    String portStr,
    PingState pingState,
  ) async {
    final port = int.tryParse(portStr);
    if (address.isEmpty || port == null || port <= 0 || port > 65535) {
      return PingDelayConstants.unknown;
    }
    final timeoutMs = (pingState.timeout * 1000).toInt();
    final start = DateTime.now().millisecondsSinceEpoch;
    try {
      final socket = await Socket.connect(
        address,
        port,
        timeout: Duration(milliseconds: timeoutMs),
      );
      final delay = DateTime.now().millisecondsSinceEpoch - start;
      socket.destroy();
      return delay;
    } on SocketException {
      return PingDelayConstants.timeout;
    } catch (_) {
      return PingDelayConstants.error;
    }
  }

  Future<void> _pingConfigs(AppDatabase db, List<CoreConfigData> rows) async {
    final pingState = PingState();
    await pingState.readFromPreferences();
    var concurrency = pingState.concurrency.toInt();
    if (AppPlatform.isLinux || AppPlatform.isWindows) {
      concurrency = 1;
    }
    final slices = rows.slices(concurrency);
    for (final slice in slices) {
      final tempRows = <CoreConfigData>[];
      final group = FutureGroup<int>();
      for (final row in slice) {
        tempRows.add(row);
        _addTaskToGroup(group, row, pingState);
      }
      group.close();
      final res = await group.future;
      for (int i = 0; i < tempRows.length; i++) {
        await _updateRow(db, tempRows[i], res[i]);
      }
    }
  }

  void _addTaskToGroup(
    FutureGroup group,
    CoreConfigData row,
    PingState pingState,
  ) {
    final type = CoreConfigType.fromString(row.type);
    if (type != null) {
      switch (type) {
        case CoreConfigType.outbound:
          group.add(_pingOutbound(row, pingState));
          break;
        default:
          group.add(Future.value(PingDelayConstants.unknown));
          break;
      }
    }
  }

  Future<void> _updateRow(AppDatabase db, CoreConfigData row, int delay) async {
    var newRow = row;
    if (delay != PingDelayConstants.unknown) {
      newRow = newRow.copyWith(delay: delay);
    }
    await db.coreConfigDao.updateRow(newRow);
  }

  String parsePingResponse(int delay) {
    var content = "";
    switch (delay) {
      case PingDelayConstants.timeout:
        content = appLocalizationsNoContext().pingTimeout;
        break;
      case PingDelayConstants.error:
        content = "error";
        break;
      default:
        content = "${delay}ms";
        break;
    }

    return content;
  }
}
