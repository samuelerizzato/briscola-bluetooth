import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultTile extends StatefulWidget {
  const ScanResultTile({
    super.key,
    required this.result,
    required this.isLoading,
    this.onTap,
  });

  final ScanResult result;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  State<StatefulWidget> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  late StreamSubscription<BluetoothConnectionState>
  _connectionStateSubscription;

  bool get isConnected =>
      _connectionState == BluetoothConnectionState.connected;

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription = widget.result.device.connectionState.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothDevice device = widget.result.device;

    return ListTile(
      enabled: !widget.isLoading,
      onTap: widget.onTap,
      leading: Icon(Icons.person_outline),
      title: Text(device.remoteId.str),
      subtitle: device.platformName.isNotEmpty
          ? Text(
              '${device.platformName}, ${isConnected ? 'Connected' : 'Not connected'}',
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Visibility(
        visible: widget.isLoading,
        child: CircularProgressIndicator(
          color: Theme.of(context).disabledColor,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
