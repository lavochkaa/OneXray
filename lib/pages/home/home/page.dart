import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/pages/global/constants.dart';
import 'package:onexray/pages/home/home/component/outbound/view.dart';
import 'package:onexray/pages/home/home/controller.dart';
import 'package:onexray/pages/theme/color.dart';
import 'package:onexray/pages/widget/menu_picker.dart';
import 'package:onexray/service/event_bus/service.dart';
import 'package:onexray/service/event_bus/state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeController(context),
      child: BlocBuilder<HomeController, HomeState>(
        builder: (context, homeState) {
          final controller = context.read<HomeController>();
          return BlocBuilder<AppEventBus, AppEventBusState>(
            builder: (context, eventState) => Scaffold(
              backgroundColor: ColorManager.scaffoldBackground(
                Theme.of(context).brightness,
              ),
              appBar: AppBar(
                backgroundColor: ColorManager.surface(context),
                elevation: 0,
                leading: IconButton(
                  onPressed: () => controller.gotoSettings(context),
                  icon: const Icon(Icons.settings_outlined),
                ),
                title: Text(
                  AppLocalizations.of(context)!.homePageTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                actions: [
                  _refreshButton(context, controller, homeState),
                  _addButton(context, controller, eventState),
                ],
              ),
              body: SafeArea(
                child: _body(context, controller, homeState, eventState),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _refreshButton(
    BuildContext context,
    HomeController controller,
    HomeState homeState,
  ) {
    if (homeState.refreshing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      onPressed: () => controller.refreshSubscriptions(context),
      icon: const Icon(Icons.refresh),
    );
  }

  Widget _addButton(
    BuildContext context,
    HomeController controller,
    AppEventBusState eventState,
  ) {
    if (eventState.downloading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconMenuPicker(
      icon: Icons.add,
      menus: [
        IconMenuId.manualInput,
        IconMenuId.subscribeLink,
        if (AppPlatform.isMobile) IconMenuId.scanQRCode,
        IconMenuId.pickImage,
        IconMenuId.pickFile,
        IconMenuId.readPasteboard,
      ],
      callback: (actionId) => controller.addMenuAction(context, actionId),
    );
  }

  Widget _body(
    BuildContext context,
    HomeController controller,
    HomeState homeState,
    AppEventBusState eventState,
  ) {
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: GlobalConstants.bodyFontSize),
      child: Column(
        children: [
          const Expanded(child: HomeOutboundView()),
          _connectPanel(context, controller, homeState, eventState),
        ],
      ),
    );
  }

  Widget _connectPanel(
    BuildContext context,
    HomeController controller,
    HomeState homeState,
    AppEventBusState eventState,
  ) {
    final isConnected = eventState.runningId != DBConstants.defaultId;
    final isLoading = eventState.vpnLoading;

    return Container(
      decoration: BoxDecoration(
        color: ColorManager.surface(context),
        border: Border(
          top: BorderSide(
            color: ColorManager.border(context),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConnected) _locationRow(context, controller, eventState),
          const SizedBox(height: 8),
          _connectButton(context, controller, eventState, isConnected, isLoading),
        ],
      ),
    );
  }

  Widget _locationRow(
    BuildContext context,
    HomeController controller,
    AppEventBusState eventState,
  ) {
    final location = eventState.location;
    final text = controller.formatGeoLocation(context, location);
    return InkWell(
      onTap: () => controller.gotoNodeInfo(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: Colors.green.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.green.shade600),
          ],
        ),
      ),
    );
  }

  Widget _connectButton(
    BuildContext context,
    HomeController controller,
    AppEventBusState eventState,
    bool isConnected,
    bool isLoading,
  ) {
    if (isLoading) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final Color btnColor = isConnected
        ? Theme.of(context).primaryColor
        : ColorManager.buttonStop(context);
    final String label = isConnected
        ? AppLocalizations.of(context)!.menuBarStopVpn
        : AppLocalizations.of(context)!.menuBarStartVpn;
    final IconData icon = isConnected ? Icons.private_connectivity : Icons.public;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () => controller.startVpn(context),
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
