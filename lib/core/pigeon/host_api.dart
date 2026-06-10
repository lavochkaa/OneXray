import 'dart:convert';

import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/model/xray_json.dart';
import 'package:onexray/core/pigeon/messages.g.dart';
import 'package:onexray/core/pigeon/model.dart';
import 'package:onexray/core/tools/json.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/service/xray/standard.dart';

class AppHostApi {
  final _api = BridgeHostApi();

  static final AppHostApi _singleton = AppHostApi._internal();

  factory AppHostApi() => _singleton;

  AppHostApi._internal();

  // ===============
  final _errorResult = "error";
  var _tunFilesDir = "";

  Future<void> initTunFilesDir() async {
    _tunFilesDir = await _api.getTunFilesDir();
  }

  Future<void> readVpnStatus() async {
    try {
      await _api.readVpnStatus();
    } catch (_) {}
  }

  Future<void> startVpn() async {
    try {
      await _api.startVpn();
    } catch (_) {}
  }

  Future<void> stopVpn() async {
    try {
      await _api.stopVpn();
    } catch (_) {}
  }

  String get tunFilesDir => _tunFilesDir;

  Future<List<int>> getFreePorts(int num) async {
    try {
      final res = await _api.getFreePorts(num);
      final resp = parseCallResponse(res);
      if (resp.success != null && resp.data != null) {
        if (resp.success!) {
          final data = resp.data as Map<String, dynamic>;
          final ports = GetFreePortsResponse.fromJson(data);
          if (ports.ports != null) {
            return ports.ports!;
          }
        }
      }
    } catch (_) {}
    return [];
  }

  Future<XrayJson> convertShareLinksToXrayJson(String text) async {
    try {
      final request = encodeStringRequest(text);
      final res = await _api.convertShareLinksToXrayJson(request);
      final resp = parseCallResponse(res);
      if (resp.success != null && resp.data != null) {
        if (resp.success!) {
          final data = resp.data as Map<String, dynamic>;
          final xrayJson = XrayJson.fromJson(data);
          return xrayJson;
        }
      }
    } catch (e) {
      ygLogger("$e");
    }
    return XrayJsonStandard.standard;
  }

  Future<String> convertXrayJsonToShareLinks(XrayJson xrayJson) async {
    try {
      final requestMap = xrayJson.toJson();
      final base64Text = JsonTool.encodeJsonToBase64(requestMap);
      final res = await _api.convertXrayJsonToShareLinks(base64Text);
      final resp = parseCallResponse(res);
      if (resp.success != null && resp.data != null) {
        if (resp.success!) {
          final data = resp.data as String;
          return data;
        }
      }
    } catch (e) {
      ygLogger("$e");
    }
    return "";
  }

  Future<String> countGeoData(CountGeoDataRequest request) async {
    try {
      final requestMap = request.toJson();
      final base64Text = JsonTool.encodeJsonToBase64(requestMap);
      final res = await _api.countGeoData(base64Text);
      final resp = parseCallResponse(res);
      if (resp.success != null) {
        if (resp.success!) {
          return "";
        } else {
          if (resp.error != null) {
            return resp.error!;
          }
        }
      }
    } catch (_) {}
    return _errorResult;
  }

  Future<ReadGeoFilesResponse> readGeoFiles(String base64Text) async {
    try {
      final res = await _api.readGeoFiles(base64Text);
      final resp = parseCallResponse(res);
      if (resp.success != null) {
        if (resp.success!) {
          final data = resp.data as Map<String, dynamic>;
          final geoFiles = ReadGeoFilesResponse.fromJson(data);
          return geoFiles;
        } else {
          if (resp.error != null) {
            return ReadGeoFilesResponse(null, null);
          }
        }
      }
    } catch (e) {
      ygLogger("$e");
    }
    return ReadGeoFilesResponse(null, null);
  }

  Future<int> ping(
    String datDir,
    String configPath,
    int timeout,
    String url,
    String proxy,
  ) async {
    try {
      final request = PingRequest(
        datDir,
        configPath,
        timeout,
        url,
        proxy,
      ).toJson();
      final base64Text = JsonTool.encodeJsonToBase64(request);
      final res = await _api.ping(base64Text);
      final resp = parseCallResponse(res);
      ygLogger(
        "ping result sucess:${resp.success} data:${resp.data} error:${resp.error}",
      );
      if (resp.data != null && resp.data is int) {
        ygLogger("ping delay: ${resp.data}");
        return resp.data as int;
      }
    } catch (e) {
      ygLogger("$e");
    }
    return PingDelayConstants.unknown;
  }

  Future<String> testXray(String datDir, String configPath) async {
    try {
      final request = RunXrayRequest(datDir, configPath).toJson();
      final base64Text = JsonTool.encodeJsonToBase64(request);
      final res = await _api.testXray(base64Text);
      final resp = parseCallResponse(res);
      if (resp.success != null) {
        if (resp.success!) {
          return "";
        } else {
          if (resp.error != null) {
            return resp.error!;
          }
        }
      }
    } catch (e) {
      ygLogger("$e");
    }
    return _errorResult;
  }

  Future<String> runXray(String datDir, String configPath) async {
    try {
      final request = RunXrayRequest(datDir, configPath).toJson();
      final base64Text = JsonTool.encodeJsonToBase64(request);
      final res = await _api.runXray(base64Text);
      final resp = parseCallResponse(res);
      if (resp.success != null) {
        if (resp.success!) {
          return "";
        } else {
          if (resp.error != null) {
            return resp.error!;
          }
        }
      }
    } catch (_) {}
    return _errorResult;
  }

  Future<String> stopXray() async {
    try {
      final res = await _api.stopXray();
      final resp = parseCallResponse(res);
      if (resp.success != null) {
        if (resp.success!) {
          return "";
        } else {
          if (resp.error != null) {
            return resp.error!;
          }
        }
      }
    } catch (_) {}
    return _errorResult;
  }

  Future<String> xrayVersion() async {
    try {
      final res = await _api.xrayVersion();
      final resp = parseCallResponse(res);
      if (resp.success != null && resp.data != null) {
        if (resp.success!) {
          return resp.data! as String;
        }
      }
    } catch (_) {}
    return "";
  }

  CallResponse parseCallResponse(String res) {
    final data = JsonTool.decodeBase64ToJson(res);
    final resp = CallResponse.fromJson(data);
    return resp;
  }

  String encodeStringRequest(String request) {
    final data = utf8.encode(request);
    final base64Text = base64Encode(data);
    return base64Text;
  }

  Future<bool> checkVpnPermission() async {
    if (AppPlatform.isIOS || AppPlatform.isMacOS) {
      try {
        final result = await _api.checkVpnPermission();
        return result;
      } catch (_) {}
    }
    return true;
  }

  Future<List<AndroidAppInfo>> getInstalledApps() async {
    return [];
  }

  Future<bool> useSystemExtension() async {
    return false;
  }

  Future<bool> setAppIcon(String appIcon) async {
    if (AppPlatform.isIOS) {
      try {
        return await _api.setAppIcon(appIcon);
      } catch (_) {}
    }
    return false;
  }

  Future<String> getCurrentAppIcon() async {
    if (AppPlatform.isIOS) {
      try {
        return await _api.getCurrentAppIcon();
      } catch (_) {}
    }
    return "";
  }
}
