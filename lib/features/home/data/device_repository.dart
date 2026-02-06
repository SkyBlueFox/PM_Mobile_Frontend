import '../models/device_widget.dart';
import 'mqtt/mqtt_service.dart';
import 'mqtt/widget_update.dart';

class DevicesRepository {
  final MqttService mqtt;

  DevicesRepository({required this.mqtt});

  // For now mock fetch; later replace with real REST call
  Future<List<DeviceWidget>> fetchWidgets() async { //TODO: implement real fetch
    return const <DeviceWidget>[];
  }

  Future<void> connectRealtime() => mqtt.connect();

  Stream<WidgetUpdate> realtimeUpdates() => mqtt.updates;

  Future<void> disconnectRealtime() => mqtt.disconnect();
}
