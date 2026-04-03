import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'image_helper.dart';
import 'package:image/image.dart' as img;

String formatCOP(double value) {
  return '\$${value.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Impresora de Facturas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrinterManager _printerManager = PrinterManager();
  PrinterDevice? _connectedPrinter;
  String _printerStatus = 'Sin conectar';
  final List<Map<String, dynamic>> _facturas = [];
  Map<String, dynamic>? _negocio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFacturas();
    _loadNegocio();
  }

  Future<void> _loadFacturas() async {
    try {
      final facturas = await DatabaseHelper.instance.getFacturas();
      debugPrint('DEBUG: Facturas cargadas: ${facturas.length}');
      setState(() {
        _facturas.addAll(facturas);
      });
    } catch (e) {
      debugPrint('DEBUG: Error cargando facturas: $e');
    }
  }

  Future<void> _loadNegocio() async {
    final negocio = await DatabaseHelper.instance.getNegocio();
    setState(() {
      _negocio = negocio;
      _isLoading = false;
    });
  }

  Future<void> _addFactura(Map<String, dynamic> factura) async {
    try {
      debugPrint('DEBUG: Intentando guardar factura: $factura');
      final id = await DatabaseHelper.instance.insertFactura(factura);
      debugPrint('DEBUG: Factura guardada con ID: $id');
      setState(() {
        _facturas.insert(0, {...factura, 'id': id});
      });
    } catch (e) {
      debugPrint('DEBUG: Error guardando factura: $e');
    }
  }

  Future<void> _updateFactura(int index, Map<String, dynamic> factura) async {
    final existingId = _facturas[index]['id'] as int;
    await DatabaseHelper.instance.updateFactura(existingId, factura);
    setState(() {
      _facturas[index] = {...factura, 'id': existingId};
    });
  }

  void _updatePrinterStatus(String status, PrinterDevice? device) {
    setState(() {
      _printerStatus = status;
      _connectedPrinter = device;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impresora de Facturas'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(color: Colors.blue.shade700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Sistema de Facturación',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _connectedPrinter != null
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        size: 16,
                        color: _connectedPrinter != null
                            ? Colors.greenAccent
                            : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _connectedPrinter?.name ?? 'Sin conectar',
                          style: TextStyle(
                            color: _connectedPrinter != null
                                ? Colors.greenAccent
                                : Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Crear Factura'),
              onTap: () {
                Navigator.pop(context);
                if (_connectedPrinter == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BluetoothScreen(
                        printerManager: _printerManager,
                        onStatusChange: _updatePrinterStatus,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateInvoiceScreen(
                        printerManager: _printerManager,
                        connectedPrinter: _connectedPrinter,
                        onFacturaCreada: (factura) {
                          _addFactura(factura);
                        },
                        getSiguienteConsecutivo: () async {
                          return await DatabaseHelper.instance
                              .getSiguienteConsecutivo();
                        },
                        negocio: _negocio,
                      ),
                    ),
                  ).then((_) => _loadNegocio());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Editar Plantilla'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditInvoiceScreen(
                      printerManager: _printerManager,
                      connectedPrinter: _connectedPrinter,
                    ),
                  ),
                ).then((_) => _loadNegocio());
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Clientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Productos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductosScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Facturas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FacturasScreen(
                      printerManager: _printerManager,
                      connectedPrinter: _connectedPrinter,
                      facturas: _facturas,
                      onFacturaActualizada: (index, factura) {
                        _updateFactura(index, factura);
                      },
                      negocio: _negocio,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Conexión Bluetooth'),
              subtitle: Text(_printerStatus),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BluetoothScreen(
                      printerManager: _printerManager,
                      onStatusChange: _updatePrinterStatus,
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('v1.0.0', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade700, Colors.blue.shade50],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildOptionCard(
                  icon: Icons.add_circle_outline,
                  title: 'Crear Factura',
                  subtitle: 'Generar nueva factura',
                  color: Colors.green,
                  onTap: () {
                    if (_connectedPrinter == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BluetoothScreen(
                            printerManager: _printerManager,
                            onStatusChange: _updatePrinterStatus,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateInvoiceScreen(
                            printerManager: _printerManager,
                            connectedPrinter: _connectedPrinter,
                            onFacturaCreada: (factura) {
                              _addFactura(factura);
                            },
                            getSiguienteConsecutivo: () async {
                              return await DatabaseHelper.instance
                                  .getSiguienteConsecutivo();
                            },
                            negocio: _negocio,
                          ),
                        ),
                      ).then((_) => _loadNegocio());
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: Icons.edit_note,
                  title: 'Editar Plantilla',
                  subtitle: 'Modificar plantilla',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditInvoiceScreen(
                        printerManager: _printerManager,
                        connectedPrinter: _connectedPrinter,
                      ),
                    ),
                  ).then((_) => _loadNegocio()),
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: Icons.people,
                  title: 'Clientes',
                  subtitle: 'Ver clientes registrados',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientesScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: Icons.inventory_2,
                  title: 'Productos',
                  subtitle: 'Ver productos y servicios',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductosScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: Icons.receipt_long,
                  title: 'Facturas',
                  subtitle: 'Ver facturas creadas',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FacturasScreen(
                        printerManager: _printerManager,
                        connectedPrinter: _connectedPrinter,
                        facturas: _facturas,
                        onFacturaActualizada: (index, factura) {
                          _updateFactura(index, factura);
                        },
                        negocio: _negocio,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildOptionCard(
                  icon: Icons.bluetooth,
                  title: 'Conexión Bluetooth',
                  subtitle: _connectedPrinter?.name ?? 'Sin conectar',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BluetoothScreen(
                        printerManager: _printerManager,
                        onStatusChange: _updatePrinterStatus,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

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
                          title: Text(device.name ?? 'Impresora'),
                          subtitle: Text(
                            device is BluetoothPrinterDevice
                                ? (device as BluetoothPrinterDevice).address ??
                                      ''
                                : '',
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

class CreateInvoiceScreen extends StatefulWidget {
  final PrinterManager printerManager;
  final PrinterDevice? connectedPrinter;
  final Function(Map<String, dynamic>)? onFacturaCreada;
  final Future<int> Function()? getSiguienteConsecutivo;
  final Map<String, dynamic>? negocio;
  const CreateInvoiceScreen({
    super.key,
    required this.printerManager,
    this.connectedPrinter,
    this.onFacturaCreada,
    this.getSiguienteConsecutivo,
    this.negocio,
  });
  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  bool _isPrinting = false;
  String _status = 'Listo';
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _infoAdicionalController =
      TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _atendidoPorController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _serieController = TextEditingController();
  final TextEditingController _estadoActualController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _abonoController = TextEditingController();
  List<Map<String, dynamic>> _clientes = [];
  Map<String, dynamic>? _clienteSeleccionado;
  List<Map<String, dynamic>> _productos = [];

  @override
  void initState() {
    super.initState();
    _loadClientes();
    _loadProductos();
  }

  Future<void> _loadClientes() async {
    final clientes = await DatabaseHelper.instance.getClientes();
    setState(() {
      _clientes = clientes;
    });
  }

  Future<void> _loadProductos() async {
    final productos = await DatabaseHelper.instance.getProductos();
    setState(() {
      _productos = productos;
    });
  }

  void _seleccionarCliente(Map<String, dynamic> cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _clienteController.text = cliente['nombre'] ?? '';
      _telefonoController.text = cliente['telefono'] ?? '';
      _emailController.text = cliente['email'] ?? '';
      _documentoController.text = cliente['documento'] ?? '';
      _infoAdicionalController.text = cliente['info_adicional'] ?? '';
      _direccionController.text = cliente['direccion'] ?? '';
    });
  }

  Future<void> _guardarCliente() async {
    if (_clienteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el nombre del cliente')),
      );
      return;
    }
    final clienteId = await DatabaseHelper.instance.insertCliente({
      'nombre': _clienteController.text,
      'telefono': _telefonoController.text,
      'email': _emailController.text,
      'documento': _documentoController.text,
      'info_adicional': _infoAdicionalController.text,
    });
    await _loadClientes();
    setState(() {
      _clienteSeleccionado = {
        'id': clienteId,
        'nombre': _clienteController.text,
      };
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cliente guardado')));
    }
  }

  void _mostrarSelectorClientes() {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredClientes = _clientes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seleccionar Cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar cliente...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filteredClientes = _clientes.where((c) {
                            final nombre = (c['nombre'] ?? '').toLowerCase();
                            final documento = (c['documento'] ?? '')
                                .toLowerCase();
                            final telefono = (c['telefono'] ?? '')
                                .toLowerCase();
                            final search = value.toLowerCase();
                            return nombre.contains(search) ||
                                documento.contains(search) ||
                                telefono.contains(search);
                          }).toList();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: filteredClientes.isEmpty
                    ? const Center(child: Text('No hay clientes registrados'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filteredClientes.length,
                        itemBuilder: (context, index) {
                          final cliente = filteredClientes[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(cliente['nombre'] ?? ''),
                            subtitle: Text(
                              '${cliente['telefono'] ?? ''} - ${cliente['documento'] ?? ''}',
                            ),
                            onTap: () {
                              _seleccionarCliente(cliente);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _agregarItem() {
    if (_itemController.text.isNotEmpty && _precioController.text.isNotEmpty) {
      setState(() {
        _items.add({
          'nombre': _itemController.text,
          'precio': double.tryParse(_precioController.text) ?? 0.0,
        });
        _itemController.clear();
        _precioController.clear();
      });
    }
  }

  void _mostrarSelectorProductos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seleccionar Producto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _productos.isEmpty
                  ? const Center(child: Text('No hay productos registrados'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _productos.length,
                      itemBuilder: (context, index) {
                        final producto = _productos[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.inventory, color: Colors.white),
                          ),
                          title: Text(producto['nombre'] ?? ''),
                          onTap: () {
                            _itemController.text = producto['nombre'] ?? '';
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double get _total =>
      _items.fold(0.0, (sum, item) => sum + (item['precio'] as double));

  double get _abono => double.tryParse(_abonoController.text) ?? 0.0;

  double get _saldo => _total - _abono;

  Future<void> _imprimirFactura() async {
    if (widget.connectedPrinter == null) {
      setState(() => _status = 'No hay impresora conectada');
      return;
    }
    setState(() {
      _isPrinting = true;
      _status = 'Imprimiendo...';
    });
    try {
      final negocio = widget.negocio;
      final ticket = await Ticket.create(PaperSize.mm58);

      if (negocio != null && negocio['logo'] != null) {
        try {
          final logoData = negocio['logo'] as img.Image;
          debugPrint(
            'DEBUG: Logo dimensions: ${logoData.width}x${logoData.height}',
          );
          ticket.image(logoData, align: PrintAlign.center);
          debugPrint('DEBUG: Logo printed successfully');
        } catch (e) {
          debugPrint('Error printing logo: $e');
        }
      }

      if (negocio != null &&
          negocio['nombre'] != null &&
          negocio['nombre'].isNotEmpty) {
        ticket.text(
          negocio['nombre'],
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
      }
      if (negocio != null &&
          negocio['nit'] != null &&
          negocio['nit'].isNotEmpty) {
        ticket.text(negocio['nit'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['direccion'] != null &&
          negocio['direccion'].isNotEmpty) {
        String dir = negocio['direccion'];
        if (negocio['ciudad'] != null && negocio['ciudad'].isNotEmpty)
          dir += ', ${negocio['ciudad']}';
        ticket.text(dir, align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['telefono1'] != null &&
          negocio['telefono1'].isNotEmpty) {
        ticket.text('Tel: ${negocio['telefono1']}', align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['correo'] != null &&
          negocio['correo'].isNotEmpty) {
        ticket.text(negocio['correo'], align: PrintAlign.center);
      }

      ticket.text('================================', align: PrintAlign.center);

      final numeroConsecutivo =
          await widget.getSiguienteConsecutivo?.call() ?? 1;
      debugPrint('DEBUG: Número consecutivo: $numeroConsecutivo');
      final codigoUnico = 'FAC-$numeroConsecutivo';

      ticket.text(
        'FACTURA #$numeroConsecutivo',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text(codigoUnico, align: PrintAlign.center);
      ticket.text(
        'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        align: PrintAlign.center,
      );

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'CLIENTE',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('================================', align: PrintAlign.center);

      if (_clienteController.text.isNotEmpty)
        ticket.text(
          'Nombre: ${_clienteController.text}',
          align: PrintAlign.left,
        );
      if (_documentoController.text.isNotEmpty)
        ticket.text(
          'Documento: ${_documentoController.text}',
          align: PrintAlign.left,
        );
      if (_telefonoController.text.isNotEmpty)
        ticket.text(
          'Telefono: ${_telefonoController.text}',
          align: PrintAlign.left,
        );
      if (_emailController.text.isNotEmpty)
        ticket.text('Correo: ${_emailController.text}', align: PrintAlign.left);
      if (_infoAdicionalController.text.isNotEmpty)
        ticket.text(
          'Info Adicional: ${_infoAdicionalController.text}',
          align: PrintAlign.left,
        );
      if (_direccionController.text.isNotEmpty)
        ticket.text(
          'Direccion: ${_direccionController.text}',
          align: PrintAlign.left,
        );

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'OTROS DATOS',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('================================', align: PrintAlign.center);

      if (_atendidoPorController.text.isNotEmpty) {
        ticket.text(
          'Atendido por: ${_atendidoPorController.text}',
          align: PrintAlign.left,
        );
      }
      if (_modeloController.text.isNotEmpty) {
        ticket.text(
          'Modelo: ${_modeloController.text}',
          align: PrintAlign.left,
        );
      }
      if (_serieController.text.isNotEmpty) {
        ticket.text('Serie: ${_serieController.text}', align: PrintAlign.left);
      }
      if (_estadoActualController.text.isNotEmpty) {
        ticket.text(
          'Estado Actual: ${_estadoActualController.text}',
          align: PrintAlign.left,
        );
      }

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'PRODUCTOS Y/O SERVICIOS',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('================================', align: PrintAlign.center);

      for (var item in _items) {
        ticket.text('${item['nombre']}', align: PrintAlign.left);
        ticket.text(
          formatCOP(item['precio'] as double),
          align: PrintAlign.right,
        );
      }

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'TOTAL: ${formatCOP(_total)}',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true, height: TextSize.size2),
      );

      if (_abono > 0) {
        ticket.text(
          'ABONO: -${formatCOP(_abono)}',
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
        ticket.text(
          'SALDO: ${formatCOP(_saldo)}',
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
      }

      if (negocio != null &&
          negocio['mensaje_pie'] != null &&
          negocio['mensaje_pie'].isNotEmpty) {
        ticket.text(
          'TERMINOS Y CONDICIONES',
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
        ticket.text(negocio['mensaje_pie'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['sitio_web'] != null &&
          negocio['sitio_web'].isNotEmpty) {
        ticket.text(negocio['sitio_web'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['whatsapp'] != null &&
          negocio['whatsapp'].isNotEmpty) {
        ticket.text(
          'WhatsApp: ${negocio['whatsapp']}',
          align: PrintAlign.center,
        );
      }
      if (negocio != null &&
          negocio['facebook'] != null &&
          negocio['facebook'].isNotEmpty) {
        ticket.text(negocio['facebook'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['instagram'] != null &&
          negocio['instagram'].isNotEmpty) {
        ticket.text(negocio['instagram'], align: PrintAlign.center);
      }

      ticket.feed(2);
      ticket.text(
        'FIRMA DEL CLIENTE',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.feed(4);
      ticket.text('________________________', align: PrintAlign.center);
      ticket.feed(2);
      ticket.cut();
      await widget.printerManager.printTicket(ticket);

      final factura = {
        'numero_consecutivo': numeroConsecutivo,
        'codigo_unico': codigoUnico,
        'cliente_id': _clienteSeleccionado?['id'],
        'cliente': _clienteController.text,
        'telefono': _telefonoController.text,
        'email': _emailController.text,
        'documento': _documentoController.text,
        'info_adicional': _infoAdicionalController.text,
        'direccion': _direccionController.text,
        'items': List.from(_items),
        'total': _total,
        'abono': _abono,
        'saldo': _saldo,
        'fecha': DateTime.now(),
        'estado': _saldo > 0 ? 'Adeudo' : 'Pagado',
        'atendido_por': _atendidoPorController.text,
        'modelo': _modeloController.text,
        'serie': _serieController.text,
        'estado_actual': _estadoActualController.text,
      };

      widget.onFacturaCreada?.call(factura);

      setState(() {
        _status = 'Impresión completada';
        _isPrinting = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isPrinting = false;
      });
    }
  }

  void _mostrarVistaPrevia() async {
    if (_clienteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el nombre del cliente')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agregue al menos un item')));
      return;
    }
    final numeroConsecutivo = await widget.getSiguienteConsecutivo?.call() ?? 1;
    final codigoUnico = 'FAC-$numeroConsecutivo';

    final negocio = await DatabaseHelper.instance.getNegocio();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Vista Previa de Factura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (negocio != null && negocio['logo'] != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: const Icon(Icons.image, size: 40),
                        ),
                      if (negocio != null && negocio['nombre'] != null)
                        Text(
                          negocio['nombre'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (negocio != null && negocio['nit'] != null)
                        Text(
                          negocio['nit'],
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      if (negocio != null && negocio['direccion'] != null)
                        Text(
                          '${negocio['direccion']}${negocio['ciudad'] != null ? ", ${negocio['ciudad']}" : ""}',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      if (negocio != null && negocio['telefono1'] != null)
                        Text(
                          'Tel: ${negocio['telefono1']}',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      if (negocio != null && negocio['correo'] != null)
                        Text(
                          negocio['correo'],
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        'FACTURA #$numeroConsecutivo',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(codigoUnico, style: const TextStyle(fontSize: 10)),
                      Text(
                        'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const Text(
                        'CLIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      if (_clienteController.text.isNotEmpty)
                        Text(
                          'Nombre: ${_clienteController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_documentoController.text.isNotEmpty)
                        Text(
                          'Documento: ${_documentoController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_telefonoController.text.isNotEmpty)
                        Text(
                          'Telefono: ${_telefonoController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_emailController.text.isNotEmpty)
                        Text(
                          'Correo: ${_emailController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_infoAdicionalController.text.isNotEmpty)
                        Text(
                          'Info Adicional: ${_infoAdicionalController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_direccionController.text.isNotEmpty)
                        Text(
                          'Direccion: ${_direccionController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const Text(
                        'OTROS DATOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      if (_atendidoPorController.text.isNotEmpty)
                        Text(
                          'Atendido por: ${_atendidoPorController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_modeloController.text.isNotEmpty)
                        Text(
                          'Modelo: ${_modeloController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_serieController.text.isNotEmpty)
                        Text(
                          'Serie: ${_serieController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_estadoActualController.text.isNotEmpty)
                        Text(
                          'Estado Actual: ${_estadoActualController.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const Text(
                        'PRODUCTOS Y/O SERVICIOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      ..._items.map(
                        (item) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['nombre'],
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              formatCOP(item['precio'] as double),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatCOP(_total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_abono > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ABONO:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              '-${formatCOP(_abono)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SALDO:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatCOP(_saldo),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _saldo > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.negocio != null &&
                          widget.negocio!['mensaje_pie'] != null &&
                          widget.negocio!['mensaje_pie'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'TERMINOS Y CONDICIONES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.negocio!['mensaje_pie'],
                          style: const TextStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.negocio != null &&
                          widget.negocio!['sitio_web'] != null)
                        Text(
                          widget.negocio!['sitio_web'],
                          style: const TextStyle(fontSize: 9),
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['whatsapp'] != null)
                        Text(
                          'WhatsApp: ${widget.negocio!['whatsapp']}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['facebook'] != null)
                        Text(
                          widget.negocio!['facebook'],
                          style: const TextStyle(fontSize: 9),
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['instagram'] != null)
                        Text(
                          widget.negocio!['instagram'],
                          style: const TextStyle(fontSize: 9),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'FIRMA DEL CLIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '________________________',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _imprimirFactura();
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Factura'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Datos del Cliente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_clientes.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _mostrarSelectorClientes(),
                            icon: const Icon(Icons.person_search, size: 18),
                            label: const Text('Buscar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _clienteController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _guardarCliente,
                          icon: const Icon(Icons.save, color: Colors.green),
                          tooltip: 'Guardar cliente',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _documentoController,
                            decoration: const InputDecoration(
                              labelText: 'Documento',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _infoAdicionalController,
                      decoration: const InputDecoration(
                        labelText: 'Info Adicional',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Otros Datos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _atendidoPorController,
                      decoration: const InputDecoration(
                        labelText: 'Atendido por',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _modeloController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.devices),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _serieController,
                      decoration: const InputDecoration(
                        labelText: 'Serie',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _estadoActualController,
                      decoration: const InputDecoration(
                        labelText: 'Estado Actual',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Agregar Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_productos.isNotEmpty)
                          TextButton.icon(
                            onPressed: _mostrarSelectorProductos,
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Buscar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemController,
                            decoration: const InputDecoration(
                              labelText: 'Producto/Servicio',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.shopping_bag),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _agregarItem,
                          icon: const Icon(Icons.save, color: Colors.green),
                          tooltip: 'Agregar item',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _precioController,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                        prefixText: 'L ',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    if (_itemController.text.trim().isNotEmpty &&
                        _precioController.text.trim().isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () async {
                            if (_itemController.text.isEmpty ||
                                _precioController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ingrese nombre y precio'),
                                ),
                              );
                              return;
                            }
                            await DatabaseHelper.instance.insertProducto({
                              'nombre': _itemController.text,
                              'precio':
                                  double.tryParse(_precioController.text) ??
                                  0.0,
                            });
                            await _loadProductos();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Producto guardado'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Guardar como producto'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      ..._items.asMap().entries.map(
                        (e) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.value['nombre']),
                          subtitle: Text(
                            formatCOP(e.value['precio'] as double),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _items.removeAt(e.key)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'ABONO / PAGO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _abonoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto de abono',
                        prefixText: 'L ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payments),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatCOP(_total),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (_abono > 0) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ABONO:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '- ${formatCOP(_abono)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SALDO:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatCOP(_saldo),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _saldo > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.connectedPrinter != null && !_isPrinting
                  ? _mostrarVistaPrevia
                  : null,
              icon: _isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print),
              label: Text(
                _isPrinting
                    ? 'Imprimiendo...'
                    : widget.connectedPrinter == null
                    ? 'Conecte una impresora'
                    : 'Imprimir Factura',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _status.contains('Error') ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _filteredClientes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    final clientes = await DatabaseHelper.instance.getClientes();
    setState(() {
      _clientes = clientes;
      _filteredClientes = clientes;
      _isLoading = false;
    });
  }

  void _filterClientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClientes = _clientes;
      } else {
        _filteredClientes = _clientes.where((c) {
          final nombre = (c['nombre'] ?? '').toLowerCase();
          final documento = (c['documento'] ?? '').toLowerCase();
          final telefono = (c['telefono'] ?? '').toLowerCase();
          final search = query.toLowerCase();
          return nombre.contains(search) ||
              documento.contains(search) ||
              telefono.contains(search);
        }).toList();
      }
    });
  }

  void _mostrarEditarCliente(Map<String, dynamic> cliente) {
    final nombreController = TextEditingController(text: cliente['nombre']);
    final telefonoController = TextEditingController(text: cliente['telefono']);
    final emailController = TextEditingController(text: cliente['email']);
    final documentoController = TextEditingController(
      text: cliente['documento'],
    );
    final infoController = TextEditingController(
      text: cliente['info_adicional'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Editar Cliente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: documentoController,
                decoration: const InputDecoration(
                  labelText: 'Documento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: infoController,
                decoration: const InputDecoration(
                  labelText: 'Info Adicional',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await DatabaseHelper.instance.insertCliente({
                    'nombre': nombreController.text,
                    'telefono': telefonoController.text,
                    'email': emailController.text,
                    'documento': documentoController.text,
                    'info_adicional': infoController.text,
                  });
                  await _loadClientes();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cliente actualizado')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Guardar'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _eliminarCliente(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Estás seguro de eliminar a "${cliente['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete(
                'clientes',
                where: 'id = ?',
                whereArgs: [cliente['id']],
              );
              await _loadClientes();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente eliminado')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _filterClientes,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClientes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No hay clientes registrados'
                              : 'No se encontraron clientes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredClientes.length,
                    itemBuilder: (context, index) {
                      final cliente = _filteredClientes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              (cliente['nombre'] ?? '')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(color: Colors.blue.shade700),
                            ),
                          ),
                          title: Text(cliente['nombre'] ?? ''),
                          subtitle: Text(
                            '${cliente['telefono'] ?? ''} ${cliente['documento'] != null && cliente['documento'].isNotEmpty ? '- ${cliente['documento']}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _mostrarEditarCliente(cliente),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _eliminarCliente(cliente),
                              ),
                            ],
                          ),
                          onTap: () => _mostrarEditarCliente(cliente),
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

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _filteredProductos = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    final productos = await DatabaseHelper.instance.getProductos();
    setState(() {
      _productos = productos;
      _filteredProductos = productos;
      _isLoading = false;
    });
  }

  void _filterProductos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProductos = _productos;
      } else {
        _filteredProductos = _productos.where((p) {
          final nombre = (p['nombre'] ?? '').toLowerCase();
          return nombre.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _mostrarAgregarProducto() {
    final nombreController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Agregar Producto/Servicio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese el nombre del producto'),
                    ),
                  );
                  return;
                }
                await DatabaseHelper.instance.insertProducto({
                  'nombre': nombreController.text,
                });
                await _loadProductos();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto guardado')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Guardar'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _mostrarEditarProducto(Map<String, dynamic> producto) {
    final nombreController = TextEditingController(text: producto['nombre']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Editar Producto/Servicio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese el nombre del producto'),
                    ),
                  );
                  return;
                }
                await DatabaseHelper.instance.updateProducto(producto['id'], {
                  'nombre': nombreController.text,
                });
                await _loadProductos();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto actualizado')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Guardar'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _eliminarProducto(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de eliminar "${producto['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteProducto(producto['id']);
              await _loadProductos();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto eliminado')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos y Servicios'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarAgregarProducto,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _filterProductos,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProductos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No hay productos registrados'
                              : 'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProductos.length,
                    itemBuilder: (context, index) {
                      final producto = _filteredProductos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(
                              Icons.inventory,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          title: Text(producto['nombre'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () =>
                                    _mostrarEditarProducto(producto),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _eliminarProducto(producto),
                              ),
                            ],
                          ),
                          onTap: () => _mostrarEditarProducto(producto),
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

class FacturasScreen extends StatefulWidget {
  final PrinterManager printerManager;
  final PrinterDevice? connectedPrinter;
  final List<Map<String, dynamic>> facturas;
  final Function(int, Map<String, dynamic>)? onFacturaActualizada;
  final Map<String, dynamic>? negocio;
  const FacturasScreen({
    super.key,
    required this.printerManager,
    this.connectedPrinter,
    required this.facturas,
    this.onFacturaActualizada,
    this.negocio,
  });
  @override
  State<FacturasScreen> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: widget.facturas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay facturas creadas',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una factura en "Crear Factura"',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.facturas.length,
              itemBuilder: (context, index) {
                final factura = widget.facturas[index];
                final estado = factura['estado'] ?? 'Abierto';
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt, color: Colors.blue),
                    title: Text('Factura #${factura['numero_consecutivo']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${factura['cliente']} - ${formatCOP(factura['total'] as double)}',
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: estado == 'Abierto'
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              fontSize: 12,
                              color: estado == 'Abierto'
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editarFactura(index, factura),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, color: Colors.green),
                          onPressed: () => _mostrarVistaPrevia(factura),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _imprimirFactura(Map<String, dynamic> factura) async {
    if (widget.connectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay impresora conectada')),
      );
      return;
    }
    try {
      final negocio = widget.negocio;
      final ticket = await Ticket.create(PaperSize.mm58);

      if (negocio != null && negocio['logo'] != null) {
        try {
          ticket.image(negocio['logo'], align: PrintAlign.center);
        } catch (e) {}
      }

      if (negocio != null &&
          negocio['nombre'] != null &&
          negocio['nombre'].isNotEmpty) {
        ticket.text(
          negocio['nombre'],
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
      }
      if (negocio != null &&
          negocio['nit'] != null &&
          negocio['nit'].isNotEmpty) {
        ticket.text(negocio['nit'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['direccion'] != null &&
          negocio['direccion'].isNotEmpty) {
        String dir = negocio['direccion'];
        if (negocio['ciudad'] != null && negocio['ciudad'].isNotEmpty)
          dir += ', ${negocio['ciudad']}';
        ticket.text(dir, align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['telefono1'] != null &&
          negocio['telefono1'].isNotEmpty) {
        ticket.text('Tel: ${negocio['telefono1']}', align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['correo'] != null &&
          negocio['correo'].isNotEmpty) {
        ticket.text(negocio['correo'], align: PrintAlign.center);
      }

      ticket.text('================================', align: PrintAlign.center);

      ticket.text(
        'FACTURA #${factura['numero_consecutivo']}',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text(factura['codigo_unico'] ?? '', align: PrintAlign.center);

      String fechaStr = '';
      if (factura['fecha'] != null) {
        final fecha = factura['fecha'];
        if (fecha is DateTime) {
          fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
        } else if (fecha is String) {
          fechaStr = fecha;
        }
      }
      if (fechaStr.isNotEmpty) {
        ticket.text('Fecha: $fechaStr', align: PrintAlign.center);
      }

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'CLIENTE',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('================================', align: PrintAlign.center);

      if (factura['cliente'] != null && factura['cliente'].isNotEmpty) {
        ticket.text('Nombre: ${factura['cliente']}', align: PrintAlign.left);
      }
      if (factura['documento'] != null && factura['documento'].isNotEmpty) {
        ticket.text(
          'Documento: ${factura['documento']}',
          align: PrintAlign.left,
        );
      }
      if (factura['telefono'] != null && factura['telefono'].isNotEmpty) {
        ticket.text('Telefono: ${factura['telefono']}', align: PrintAlign.left);
      }
      if (factura['email'] != null && factura['email'].isNotEmpty) {
        ticket.text('Correo: ${factura['email']}', align: PrintAlign.left);
      }
      if (factura['info_adicional'] != null &&
          factura['info_adicional'].isNotEmpty) {
        ticket.text(
          'Info Adicional: ${factura['info_adicional']}',
          align: PrintAlign.left,
        );
      }
      if (factura['direccion'] != null && factura['direccion'].isNotEmpty) {
        ticket.text(
          'Direccion: ${factura['direccion']}',
          align: PrintAlign.left,
        );
      }

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'OTROS DATOS',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('================================', align: PrintAlign.center);

      if (factura['atendido_por'] != null &&
          factura['atendido_por'].isNotEmpty) {
        ticket.text(
          'Atendido por: ${factura['atendido_por']}',
          align: PrintAlign.left,
        );
      }
      if (factura['modelo'] != null && factura['modelo'].isNotEmpty) {
        ticket.text('Modelo: ${factura['modelo']}', align: PrintAlign.left);
      }
      if (factura['serie'] != null && factura['serie'].isNotEmpty) {
        ticket.text('Serie: ${factura['serie']}', align: PrintAlign.left);
      }
      if (factura['estado_actual'] != null &&
          factura['estado_actual'].isNotEmpty) {
        ticket.text(
          'Estado Actual: ${factura['estado_actual']}',
          align: PrintAlign.left,
        );
      }

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'PRODUCTOS Y/O SERVICIOS',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('================================', align: PrintAlign.center);

      for (var item in factura['items']) {
        ticket.text('${item['nombre']}', align: PrintAlign.left);
        ticket.text(
          formatCOP(item['precio'] as double),
          align: PrintAlign.right,
        );
      }

      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'TOTAL: ${formatCOP(factura['total'] as double)}',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true, height: TextSize.size2),
      );

      if (negocio != null &&
          negocio['mensaje_pie'] != null &&
          negocio['mensaje_pie'].isNotEmpty) {
        ticket.text(
          'TERMINOS Y CONDICIONES',
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
        ticket.text(negocio['mensaje_pie'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['sitio_web'] != null &&
          negocio['sitio_web'].isNotEmpty) {
        ticket.text(negocio['sitio_web'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['whatsapp'] != null &&
          negocio['whatsapp'].isNotEmpty) {
        ticket.text(
          'WhatsApp: ${negocio['whatsapp']}',
          align: PrintAlign.center,
        );
      }
      if (negocio != null &&
          negocio['facebook'] != null &&
          negocio['facebook'].isNotEmpty) {
        ticket.text(negocio['facebook'], align: PrintAlign.center);
      }
      if (negocio != null &&
          negocio['instagram'] != null &&
          negocio['instagram'].isNotEmpty) {
        ticket.text(negocio['instagram'], align: PrintAlign.center);
      }

      ticket.feed(2);
      ticket.text(
        'FIRMA DEL CLIENTE',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.feed(4);
      ticket.text('________________________', align: PrintAlign.center);
      ticket.feed(2);
      ticket.cut();
      await widget.printerManager.printTicket(ticket);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _mostrarVistaPrevia(Map<String, dynamic> factura) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Vista Previa de Factura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.negocio != null &&
                          widget.negocio!['nombre'] != null)
                        Text(
                          widget.negocio!['nombre'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['nit'] != null)
                        Text(
                          widget.negocio!['nit'],
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['direccion'] != null)
                        Text(
                          '${widget.negocio!['direccion']}${widget.negocio!['ciudad'] != null ? ", ${widget.negocio!['ciudad']}" : ""}',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      Text(
                        'FACTURA #${factura['numero_consecutivo']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        factura['codigo_unico'] ?? '',
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        'Fecha: ${factura['fecha'] != null ? _formatFecha(factura['fecha']) : ""}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const Text(
                        'CLIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      if (factura['cliente'] != null &&
                          factura['cliente'].isNotEmpty)
                        Text(
                          'Nombre: ${factura['cliente']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['documento'] != null &&
                          factura['documento'].isNotEmpty)
                        Text(
                          'Documento: ${factura['documento']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['telefono'] != null &&
                          factura['telefono'].isNotEmpty)
                        Text(
                          'Telefono: ${factura['telefono']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['email'] != null &&
                          factura['email'].isNotEmpty)
                        Text(
                          'Correo: ${factura['email']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['info_adicional'] != null &&
                          factura['info_adicional'].isNotEmpty)
                        Text(
                          'Info Adicional: ${factura['info_adicional']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['direccion'] != null &&
                          factura['direccion'].isNotEmpty)
                        Text(
                          'Direccion: ${factura['direccion']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const Text(
                        'OTROS DATOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      if (factura['atendido_por'] != null &&
                          factura['atendido_por'].isNotEmpty)
                        Text(
                          'Atendido por: ${factura['atendido_por']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['modelo'] != null &&
                          factura['modelo'].isNotEmpty)
                        Text(
                          'Modelo: ${factura['modelo']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['serie'] != null &&
                          factura['serie'].isNotEmpty)
                        Text(
                          'Serie: ${factura['serie']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (factura['estado_actual'] != null &&
                          factura['estado_actual'].isNotEmpty)
                        Text(
                          'Estado Actual: ${factura['estado_actual']}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      const Text(
                        'PRODUCTOS Y/O SERVICIOS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      ...(factura['items'] as List).map(
                        (item) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['nombre'],
                              style: const TextStyle(fontSize: 10),
                            ),
                            Text(
                              formatCOP(item['precio'] as double),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '================================',
                        style: TextStyle(fontSize: 10),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatCOP(factura['total'] as double),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.negocio != null &&
                          widget.negocio!['mensaje_pie'] != null &&
                          widget.negocio!['mensaje_pie'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'TERMINOS Y CONDICIONES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.negocio!['mensaje_pie'],
                          style: const TextStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (widget.negocio != null &&
                          widget.negocio!['sitio_web'] != null)
                        Text(
                          widget.negocio!['sitio_web'],
                          style: const TextStyle(fontSize: 9),
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['whatsapp'] != null)
                        Text(
                          'WhatsApp: ${widget.negocio!['whatsapp']}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['facebook'] != null)
                        Text(
                          widget.negocio!['facebook'],
                          style: const TextStyle(fontSize: 9),
                        ),
                      if (widget.negocio != null &&
                          widget.negocio!['instagram'] != null)
                        Text(
                          widget.negocio!['instagram'],
                          style: const TextStyle(fontSize: 9),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'FIRMA DEL CLIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '________________________',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _imprimirFactura(factura);
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha is DateTime) return '${fecha.day}/${fecha.month}/${fecha.year}';
    if (fecha is String) return fecha;
    return '';
  }

  void _editarFactura(int index, Map<String, dynamic> factura) {
    final clienteController = TextEditingController(text: factura['cliente']);
    final telefonoController = TextEditingController(text: factura['telefono']);
    final direccionController = TextEditingController(
      text: factura['direccion'],
    );
    final items = List<Map<String, dynamic>>.from(factura['items']);
    double total = factura['total'];
    String estado = factura['estado'] ?? 'Abierto';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                const Text(
                  'Editar Factura',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: clienteController,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...items.asMap().entries.map(
                  (e) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.value['nombre']),
                    subtitle: Text(formatCOP(e.value['precio'] as double)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setModalState(() {
                          total -= e.value['precio'];
                          items.removeAt(e.key);
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatCOP(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estado:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Abierto'),
                        value: 'Abierto',
                        groupValue: estado,
                        onChanged: (value) {
                          setModalState(() => estado = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cerrado'),
                        value: 'Cerrado',
                        groupValue: estado,
                        onChanged: (value) {
                          setModalState(() => estado = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final updatedFactura = {
                      ...factura,
                      'cliente': clienteController.text,
                      'telefono': telefonoController.text,
                      'direccion': direccionController.text,
                      'items': items,
                      'total': total,
                      'estado': estado,
                    };
                    widget.onFacturaActualizada?.call(index, updatedFactura);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Factura actualizada')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditInvoiceScreen extends StatefulWidget {
  final PrinterManager printerManager;
  final PrinterDevice? connectedPrinter;
  const EditInvoiceScreen({
    super.key,
    required this.printerManager,
    this.connectedPrinter,
  });
  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  img.Image? _logoImageProcessed;
  final TextEditingController _nombreNegocioController = TextEditingController(
    text: 'Mi Negocio',
  );
  final TextEditingController _nitController = TextEditingController(
    text: 'NIT: 123456789',
  );
  final TextEditingController _direccionController = TextEditingController(
    text: 'Calle Principal 123',
  );
  final TextEditingController _ciudadController = TextEditingController(
    text: 'Ciudad',
  );
  final TextEditingController _codigoPostalController = TextEditingController(
    text: '01000',
  );
  final TextEditingController _correoController = TextEditingController(
    text: 'correo@negocio.com',
  );
  final TextEditingController _telefono1Controller = TextEditingController(
    text: '12345678',
  );
  final TextEditingController _telefono2Controller = TextEditingController(
    text: '87654321',
  );
  late String _numeroConsecutivo;
  late String _codigoUnico;
  late DateTime _fechaActual;
  bool _isLoadingConsecutivo = true;
  final TextEditingController _mensajePieController = TextEditingController(
    text: 'Gracias por su compra. Vuelva pronto!',
  );
  final TextEditingController _sitioWebController = TextEditingController(
    text: 'www.minegocio.com',
  );
  final TextEditingController _facebookController = TextEditingController(
    text: '@miFacebook',
  );
  final TextEditingController _instagramController = TextEditingController(
    text: '@miInstagram',
  );
  final TextEditingController _whatsappController = TextEditingController(
    text: '+504 12345678',
  );
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fechaActual = DateTime.now();
    _loadNegocio();
    _loadConsecutivo();
  }

  Future<void> _loadConsecutivo() async {
    final siguiente = await DatabaseHelper.instance.getSiguienteConsecutivo();
    if (mounted) {
      setState(() {
        _numeroConsecutivo = siguiente.toString();
        _codigoUnico = 'FAC-$siguiente';
        _isLoadingConsecutivo = false;
      });
    }
  }

  Future<void> _loadNegocio() async {
    final negocio = await DatabaseHelper.instance.getNegocio();
    if (negocio != null && mounted) {
      setState(() {
        if (negocio['logo'] != null) _logoImageProcessed = negocio['logo'];
        _nombreNegocioController.text = negocio['nombre'] ?? '';
        _nitController.text = negocio['nit'] ?? '';
        _direccionController.text = negocio['direccion'] ?? '';
        _ciudadController.text = negocio['ciudad'] ?? '';
        _codigoPostalController.text = negocio['codigo_postal'] ?? '';
        _correoController.text = negocio['correo'] ?? '';
        _telefono1Controller.text = negocio['telefono1'] ?? '';
        _telefono2Controller.text = negocio['telefono2'] ?? '';
        _sitioWebController.text = negocio['sitio_web'] ?? '';
        _facebookController.text = negocio['facebook'] ?? '';
        _instagramController.text = negocio['instagram'] ?? '';
        _whatsappController.text = negocio['whatsapp'] ?? '';
        _mensajePieController.text = negocio['mensaje_pie'] ?? '';
      });
    }
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      await DatabaseHelper.instance.saveNegocio({
        'logo': _logoImageProcessed,
        'nombre': _nombreNegocioController.text,
        'nit': _nitController.text,
        'direccion': _direccionController.text,
        'ciudad': _ciudadController.text,
        'codigo_postal': _codigoPostalController.text,
        'correo': _correoController.text,
        'telefono1': _telefono1Controller.text,
        'telefono2': _telefono2Controller.text,
        'sitio_web': _sitioWebController.text,
        'facebook': _facebookController.text,
        'instagram': _instagramController.text,
        'whatsapp': _whatsappController.text,
        'mensaje_pie': _mensajePieController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
      }
    }
  }

  void _mostrarVistaPrevia() async {
    await _loadConsecutivo(); // Refresh before showing preview
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Vista Previa de Factura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_logoImageProcessed != null)
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              Uint8List.fromList(
                                img.encodePng(_logoImageProcessed!),
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      Text(
                        _nombreNegocioController.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _nitController.text,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${_direccionController.text}, ${_ciudadController.text}',
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                      if (_telefono1Controller.text.isNotEmpty)
                        Text(
                          'Tel: ${_telefono1Controller.text}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      if (_correoController.text.isNotEmpty)
                        Text(
                          _correoController.text,
                          style: const TextStyle(fontSize: 10),
                        ),
                      const Divider(height: 16),
                      Text(
                        'Factura #${_numeroConsecutivo}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_codigoUnico, style: const TextStyle(fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const Divider(height: 16),
                      const Text(
                        '-----------------------------',
                        style: TextStyle(fontSize: 10),
                      ),
                      const Text(
                        'CLIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '-----------------------------',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '-----------------------------',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            '\$0.00',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '-----------------------------',
                        style: TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      if (_mensajePieController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'TERMINOS Y CONDICIONES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _mensajePieController.text,
                          style: const TextStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      if (_sitioWebController.text.isNotEmpty)
                        Text(
                          _sitioWebController.text,
                          style: const TextStyle(fontSize: 9),
                        ),
                      if (_whatsappController.text.isNotEmpty)
                        Text(
                          'WhatsApp: ${_whatsappController.text}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        '*** FIN DEL TICKET ***',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Vista previa en papel de 58mm',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final processedImage = await ImageHelper.procesarLogo(bytes);
        setState(() => _logoImageProcessed = processedImage);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Plantilla'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _mostrarVistaPrevia,
            tooltip: 'Vista Previa',
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _guardar),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logo del Negocio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: _seleccionarImagen,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: _logoImageProcessed != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        Uint8List.fromList(
                                          img.encodePng(_logoImageProcessed!),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Toca para subir logo',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'La imagen se imprimirá centrada al inicio de la factura',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del Negocio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombreNegocioController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Negocio',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nitController,
                          decoration: const InputDecoration(
                            labelText: 'NIT / Identificación',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _ciudadController,
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) =>
                                    value!.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _codigoPostalController,
                                decoration: const InputDecoration(
                                  labelText: 'C.P.',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _correoController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _telefono1Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono 1',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _telefono2Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono 2',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_android),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos de Facturación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingConsecutivo)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          TextFormField(
                            initialValue: _numeroConsecutivo,
                            decoration: const InputDecoration(
                              labelText: 'Próximo Número (Ejemplo)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _codigoUnico,
                            decoration: const InputDecoration(
                              labelText: 'Código Único (Ejemplo)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                            readOnly: true,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue:
                              '${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}',
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Emisión',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Redes Sociales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sitioWebController,
                          decoration: const InputDecoration(
                            labelText: 'Sitio Web',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _facebookController,
                          decoration: const InputDecoration(
                            labelText: 'Facebook',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.facebook),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _instagramController,
                          decoration: const InputDecoration(
                            labelText: 'Instagram',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.camera_alt),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _whatsappController,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.chat),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terminos y Condiciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mensajePieController,
                          decoration: const InputDecoration(
                            labelText: 'Terminos y condiciones',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.message),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Configuración'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
