import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:onexray/core/constants/preferences.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/tools/file.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/gen/assets.gen.dart';
import 'package:onexray/pages/main/url.dart';
import 'package:onexray/service/event_bus/service.dart';
import 'package:onexray/core/pigeon/constants.dart';
import 'package:onexray/service/subscription/service.dart';
import 'package:onexray/service/xray/outbound/enum.dart';
import 'package:onexray/service/xray/outbound/state.dart';
import 'package:onexray/service/xray/outbound/state_db.dart';
import 'package:path/path.dart' as p;

Future<void> initRouter(BuildContext context) async {
  await _initTheme(context);
  final privacyAccepted = await PreferencesKey().readPrivacyAccepted();
  if (context.mounted) {
    if (privacyAccepted) {
      await checkFirstRun(context);
    } else {
      context.go(RouterPath.privacy);
    }
  }
}

Future<void> checkFirstRun(BuildContext context) async {
  try {
    await _initApp(context);
  } catch (e) {
    appLog('Init', 'checkFirstRun _initApp error=$e');
  }
  if (context.mounted) {
    context.go(RouterPath.home);
  }
}

Future<void> _initApp(BuildContext context) async {
  if (context.mounted) {
    try {
      await _initService(context).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          appLog('Init', '_initService timed out after 15s');
        },
      );
    } catch (e) {
      appLog('Init', '_initService error=$e');
    }
  }

  try {
    await _checkSystemDat();
    appLog('Init', '_checkSystemDat ok');
  } catch (e) {
    appLog('Init', '_checkSystemDat error=$e');
  }

  await _seedDefaultConfig();
}

Future<void> _initTheme(BuildContext context) async {
  final eventBus = context.read<AppEventBus>();
  await eventBus.asyncInitTheme();
}

Future<void> _initService(BuildContext context) async {
  final eventBus = context.read<AppEventBus>();
  await eventBus.asyncInitService(context);
}

Future<void> _seedDefaultConfig() async {
  appLog('Init', '_seedDefaultConfig: checking flag');
  final already = await PreferencesKey().readDefaultConfigSeeded();
  if (already) {
    appLog('Init', '_seedDefaultConfig: already seeded, skip');
    return;
  }
  await PreferencesKey().saveDefaultConfigSeeded();

  const subUrl = 'https://ru.vpntoptop.top/api/sub/rXxmaBRLXQqnbW3F';
  appLog('Init', '_seedDefaultConfig: fetching subscription $subUrl');
  try {
    final count = await SubscriptionService().insertSubscription(
      'MIRA VPN',
      subUrl,
      false,
    );
    appLog('Init', '_seedDefaultConfig: subscription count=$count');
    if (count > 0) {
      final db = AppDatabase();
      final subs = await db.subscriptionDao.allRows;
      final sub = subs.lastWhere(
        (s) => s.url == subUrl,
        orElse: () => subs.last,
      );
      final configs = await db.coreConfigDao.allOutboundRowsWithDataBySubId(
        sub.id,
      );
      if (configs.isNotEmpty) {
        await PreferencesKey().saveLastConfigId(configs.first.id);
        appLog(
          'Init',
          '_seedDefaultConfig: lastConfigId=${configs.first.id} name=${configs.first.name}',
        );
      }
      return;
    }
  } catch (e, st) {
    appLog('Init', '_seedDefaultConfig subscription error=$e\n$st');
  }

  // Fallback: subscription fetch failed — insert hardcoded MIRA CB | LTE config.
  appLog('Init', '_seedDefaultConfig: fallback to hardcoded config');
  try {
    final state = OutboundState();
    state.name = '🇷🇺 MIRA CB | LTE';
    state.protocol = XrayOutboundProtocol.vless;
    state.address = 'ct3pwpzo4a.cdn.twcstorage.ru';
    state.port = '443';
    state.vlessId = '39be588b-45ee-462b-8738-53229113266f';
    state.vlessEncryption = 'none';
    state.vlessFlow = VLESSFlow.none;
    state.network = StreamSettingsNetwork.xhttp;
    state.security = StreamSettingsSecurity.tls;
    state.serverName = 'ct3pwpzo4a.cdn.twcstorage.ru';
    state.alpn = {StreamSettingsSecurityALPN.h2};
    state.fingerprint = StreamSettingsSecurityFingerprint.chrome;
    state.xhttpHost = 'ct3pwpzo4a.cdn.twcstorage.ru';
    state.xhttpPath = '/xx/statistic/metrics';
    state.xhttpMode = XhttpMode.packetUp;
    state.xhttpExtra = {
      'mode': 'auto',
      'path': '/xx/statistic/metrics',
      'scMaxBufferedPosts': 30,
      'scMaxEachPostBytes': 1000000,
      'scMinPostsIntervalMs': 30,
      'uplinkHTTPMethod': 'POST',
      'xPaddingHeader': 'X-Request-ID',
      'xPaddingKey': 'X-Request-ID',
      'xPaddingMethod': 'tokenish',
      'xPaddingObfsMode': true,
      'xPaddingPlacement': 'header',
      'xmux': {
        'cMaxLifetimeMs': 30000,
        'cMaxReuseTimes': '256',
        'hKeepAlivePeriod': 0,
        'hMaxRequestTimes': '600',
        'maxConcurrency': '16',
      },
    };
    final id = await state.insertToDb();
    appLog('Init', '_seedDefaultConfig: fallback inserted id=$id');
    await PreferencesKey().saveLastConfigId(id);
  } catch (e, st) {
    appLog('Init', '_seedDefaultConfig fallback error=$e\n$st');
  }
}

Future<void> _checkSystemDat() async {
  final datPath = VpnConstants.datDir;
  await FileTool.checkDir(datPath);

  final dstTimestampPath = p.join(datPath, VpnConstants.systemGeoTimestamp);
  final dstTimestampFile = File(dstTimestampPath);
  final exists = await dstTimestampFile.exists();
  if (exists) {
    var dstTimestamp = await dstTimestampFile.readAsString();
    dstTimestamp = dstTimestamp.trim();
    var srcTimestamp = await rootBundle.loadString(Assets.dat.timestamp);
    srcTimestamp = srcTimestamp.trim();
    if (srcTimestamp.compareTo(dstTimestamp) > 0) {
      await FileTool.copyAssets(Assets.dat.values, datPath);
    }
  } else {
    await FileTool.copyAssets(Assets.dat.values, datPath);
  }
}
