import 'package:flutter/material.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class BluetoothScreen extends StatefulWidget {
  final PrinterManager printerManager;
  final Function(String, PrinterDevice?) onStatusChange;

  const BluetoothScreen({
    super.key,
    required this.printerManager,
    required this.onStatusChange,
  });

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  List<PrinterDevice> _devices = [];
  PrinterDevice? _connectedPrinter;
  bool _isScanning = false;
  String _status = 'Sin conectar';

  Future<bool> _requestPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    return bluetoothScan.isGranted && bluetoothConnect.isGranted;
  }

  Future<bool> _isBluetoothEnabled() async {
    try {
      const platform = MethodChannel('com.impresora.app_impresora/bluetooth');
      final bool result = await platform.invokeMethod('isBluetoothEnabled');
      return result;
    } catch (e) {
      return true;
    }
  }

  Future<bool> _enableBluetooth() async {
    try {
      const platform = MethodChannel('com.impresora.app_impresora/bluetooth');
      final bool result = await platform.invokeMethod('enableBluetooth');
      return result;
    } catch (e) {
      return false;
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
      _status = 'Verificando permisos...';
    });
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      setState(() {
        _isScanning = false;
        _status = 'Permisos denegados';
      });
      return;
    }
    final isEnabled = await _isBluetoothEnabled();
    if (!isEnabled) {
      setState(() => _status = 'Encendiendo Bluetooth...');
      await _enableBluetooth();
      await Future.delayed(const Duration(seconds: 2));
    }
    setState(() => _status = 'Escaneando...');
    try {
      final printers = await widget.printerManager.scanPrinters(
        timeout: const Duration(seconds: 10),
        types: {PrinterConnectionType.bluetooth},
      );
      setState(() {
        _devices = printers;
        _isScanning = false;
        _status = printers.isEmpty
            ? 'No se encontraron'
            : '${printers.length} encontradas';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _connectDevice(PrinterDevice device) async {
    setState(() => _status = 'Conectando...');
    try {
      await widget.printerManager.connect(device);
      setState(() {
        _connectedPrinter = device;
        _status = 'Conectado';
      });
      widget.onStatusChange('Conectado a ${device.name}', device);
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Conexión Bluetooth'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade700,
            child: Column(
              children: [
                Icon(
                  _connectedPrinter != null
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  size: 48,
                  color: _connectedPrinter != null
                      ? Colors.greenAccent
                      : Colors.white70,
                ),
                const SizedBox(height: 8),
                Text(
                  _connectedPrinter?.name ?? 'Sin conectar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_status, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isScanning ? 'Escaneando...' : 'Buscar impresoras',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dispositivos:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(child: Text('No se encontraron dispositivos'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.print),
                          title: Text(device.name),
                          subtitle: Text(
                            (device as BluetoothPrinterDevice).address,
                          ),
                          trailing: _connectedPrinter?.name == device.name
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () => _connectDevice(device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
