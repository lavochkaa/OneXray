import 'package:flutter/material.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/pages/home/component/config_row/enum.dart';
import 'package:onexray/pages/home/component/config_row/controller.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/widget/menu_picker.dart';
import 'package:onexray/service/db/config_reader.dart';

class ConfigRowView extends StatelessWidget {
  final CoreConfigData data;
  final ConfigRowStatus status;
  final List<IconMenuId> moreMenus;
  final VoidCallback? tapCallback;

  const ConfigRowView({
    super.key,
    required this.data,
    required this.status,
    required this.moreMenus,
    required this.tapCallback,
  });

  static final _controller = ConfigRowController();

  @override
  Widget build(BuildContext context) {
    return _body(context, _controller);
  }

  Widget _body(BuildContext context, ConfigRowController controller) {
    if (tapCallback != null) {
      return InkWell(
        onTap: () => tapCallback!(),
        child: _content(context, controller),
      );
    } else {
      return _content(context, controller);
    }
  }

  Widget _content(BuildContext context, ConfigRowController controller) {
    Color bgColor;
    switch (status) {
      case ConfigRowStatus.unselected:
        bgColor = ColorManager.surface(context);
        break;
      case ConfigRowStatus.selected:
        bgColor = ColorManager.selected(context);
        break;
      case ConfigRowStatus.running:
        bgColor = ColorManager.running(context);
        break;
    }

    final protocolTag = _protocolTag(context);
    final isRunning = status == ConfigRowStatus.running;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 13, horizontal: 16),
      color: bgColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isRunning)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.green.shade400,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        data.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: ColorManager.primaryText(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (protocolTag.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 3),
                    child: Text(
                      protocolTag,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorManager.secondaryText(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _latencyBadge(context),
          if (moreMenus.isNotEmpty)
            IconMenuPicker(
              icon: Icons.more_vert,
              menus: moreMenus,
              callback: (menuId) =>
                  controller.moreAction(context, data, menuId),
            ),
        ],
      ),
    );
  }

  String _protocolTag(BuildContext context) {
    return data.readTags(context)
        .where((t) => !t.endsWith('ms') && t != 'timeout' && t != 'error')
        .join(' · ');
  }

  Widget _latencyBadge(BuildContext context) {
    final delay = data.delay;
    if (delay == PingDelayConstants.unknown) return const SizedBox.shrink();

    Color color;
    String label;

    if (delay == PingDelayConstants.timeout || delay == PingDelayConstants.error) {
      color = Colors.red.shade400;
      label = delay == PingDelayConstants.timeout ? 'timeout' : 'err';
    } else if (delay < 100) {
      color = Colors.green.shade500;
      label = '${delay}ms';
    } else if (delay < 300) {
      color = Colors.orange.shade400;
      label = '${delay}ms';
    } else {
      color = Colors.red.shade400;
      label = '${delay}ms';
    }

    return Container(
      margin: const EdgeInsetsDirectional.only(end: 4),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
