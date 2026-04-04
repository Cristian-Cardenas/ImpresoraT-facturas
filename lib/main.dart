import 'package:flutter/material.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import 'database_helper.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/clientes_screen.dart';
import 'screens/productos_screen.dart';
import 'screens/facturas_screen.dart';
import 'screens/edit_invoice_screen.dart';

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
        _facturas.clear();
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

  void _navigateToCreateInvoice() {
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
            onFacturaCreada: _addFactura,
            getSiguienteConsecutivo: () async {
              return await DatabaseHelper.instance.getSiguienteConsecutivo();
            },
            negocio: _negocio,
          ),
        ),
      ).then((_) => _loadNegocio());
    }
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
      drawer: _buildDrawer(),
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
                  onTap: _navigateToCreateInvoice,
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
                        onFacturaActualizada: _updateFactura,
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

  Widget _buildDrawer() {
    return Drawer(
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
              _navigateToCreateInvoice();
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
                MaterialPageRoute(builder: (context) => const ClientesScreen()),
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
                    onFacturaActualizada: _updateFactura,
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
