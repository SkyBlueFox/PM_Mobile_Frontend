import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'widget_update.dart';

class MqttService {
  final String broker;
  final int port;
  final String clientId;

  MqttServerClient? _client;
  final _ctrl = StreamController<WidgetUpdate>.broadcast();

  Stream<WidgetUpdate> get updates => _ctrl.stream;

  MqttService({
    required this.broker,
    required this.port,
    required this.clientId,
  });

  Future<void> connect() async {
    final client = MqttServerClient(broker, clientId);
    client.port = port;
    client.keepAlivePeriod = 30;
    client.logging(on: false);

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client = client;

    try {
      await client.connect();
    } catch (_) {
      client.disconnect();
      rethrow;
    }

    // Subscribe wildcard topic: pm/widgets/<widgetId>/state
    client.subscribe('pm/widgets/+/state', MqttQos.atLeastOnce);

    client.updates?.listen((events) {
      for (final e in events) {
        final topic = e.topic;
        final msg = e.payload as MqttPublishMessage;
        final payloadStr =
            MqttPublishPayload.bytesToStringAsString(msg.payload.message);

        final update = _parse(topic, payloadStr);
        if (update != null) _ctrl.add(update);
      }
    });
  }

  WidgetUpdate? _parse(String topic, String payloadStr) {
    // Expect: pm/widgets/<id>/state
    final parts = topic.split('/');
    if (parts.length != 4) return null;
    if (parts[0] != 'pm' || parts[1] != 'widgets' || parts[3] != 'state') return null;

    final widgetId = int.tryParse(parts[2]);
    if (widgetId == null) return null;

    // Payload can be {"value":70} or "70"
    try {
      final decoded = jsonDecode(payloadStr);
      if (decoded is Map<String, dynamic>) {
        final v = decoded['value'];
        if (v is num) return WidgetUpdate(widgetId: widgetId, value: v.toDouble());
      }
    } catch (_) {
      final v = double.tryParse(payloadStr);
      if (v != null) return WidgetUpdate(widgetId: widgetId, value: v);
    }

    return null;
  }

  Future<void> disconnect() async {
    _client?.disconnect();
    await _ctrl.close();
  }
}
