import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../helpers/formatters.dart';
import '../widgets/factura_preview_widget.dart';
import '../services/ticket_printer_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final dynamic printerManager;
  final dynamic connectedPrinter;
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
  late final TicketPrinterService _printerService;
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _infoAdicionalController =
      TextEditingController();
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
    _printerService = TicketPrinterService(
      printerManager: widget.printerManager,
    );
    _loadClientes();
    _loadProductos();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _documentoController.dispose();
    _infoAdicionalController.dispose();
    _atendidoPorController.dispose();
    _modeloController.dispose();
    _serieController.dispose();
    _estadoActualController.dispose();
    _itemController.dispose();
    _precioController.dispose();
    _abonoController.dispose();
    super.dispose();
  }

  Future<void> _loadClientes() async {
    final clientes = await DatabaseHelper.instance.getClientes();
    if (mounted) setState(() => _clientes = clientes);
  }

  Future<void> _loadProductos() async {
    final productos = await DatabaseHelper.instance.getProductos();
    if (mounted) setState(() => _productos = productos);
  }

  double get _total => _items.fold(
    0.0,
    (sum, item) => sum + ((item['precio'] as num?)?.toDouble() ?? 0.0),
  );
  double get _abono => double.tryParse(_abonoController.text) ?? 0.0;
  double get _saldo => _total - _abono;

  void _agregarItem(String nombre, double precio) {
    setState(() {
      _items.add({'nombre': nombre, 'precio': precio});
      _itemController.clear();
      _precioController.clear();
    });
  }

  Future<void> _imprimirFactura() async {
    if (widget.connectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay impresora conectada')),
      );
      return;
    }
    setState(() {});
    try {
      final numeroConsecutivo =
          await widget.getSiguienteConsecutivo?.call() ?? 1;
      final codigoUnico = 'FAC-$numeroConsecutivo';

      await _printerService.printTicketFromControllers(
        connectedPrinter: widget.connectedPrinter,
        context: context,
        negocio: widget.negocio,
        cliente: _clienteController.text,
        documento: _documentoController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
        infoAdicional: _infoAdicionalController.text,
        atendidoPor: _atendidoPorController.text,
        modelo: _modeloController.text,
        serie: _serieController.text,
        estadoActual: _estadoActualController.text,
        items: List.from(_items),
        total: _total,
        abono: _abono,
        numeroConsecutivo: numeroConsecutivo,
      );

      final factura = {
        'numero_consecutivo': numeroConsecutivo,
        'codigo_unico': codigoUnico,
        'cliente_id': _clienteSeleccionado?['id'],
        'cliente': _clienteController.text,
        'telefono': _telefonoController.text,
        'email': _emailController.text,
        'documento': _documentoController.text,
        'info_adicional': _infoAdicionalController.text,
        'items': List.from(_items),
        'total': _total,
        'abono': _abono,
        'saldo': _saldo,
        'fecha': DateTime.now(),
        'estado': _saldo > 0 ? 'Debe' : 'Pagado',
        'atendido_por': _atendidoPorController.text,
        'modelo': _modeloController.text,
        'serie': _serieController.text,
        'estado_actual': _estadoActualController.text,
      };

      widget.onFacturaCreada?.call(factura);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Impresión completada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al imprimir: $e')));
      }
    } finally {
      if (mounted) setState(() {});
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

    final facturaData = {
      'numero_consecutivo': numeroConsecutivo,
      'codigo_unico': codigoUnico,
      'cliente': _clienteController.text,
      'telefono': _telefonoController.text,
      'email': _emailController.text,
      'documento': _documentoController.text,
      'info_adicional': _infoAdicionalController.text,
      'atendido_por': _atendidoPorController.text,
      'modelo': _modeloController.text,
      'serie': _serieController.text,
      'estado_actual': _estadoActualController.text,
      'items': _items,
      'total': _total,
      'abono': _abono,
      'fecha': DateTime.now(),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
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
                  FacturaPreviewWidget(
                    factura: facturaData,
                    negocio: widget.negocio,
                    onImprimir: () {
                      Navigator.pop(context);
                      _imprimirFactura();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  void _seleccionarCliente(Map<String, dynamic> cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _clienteController.text = cliente['nombre'] ?? '';
      _telefonoController.text = cliente['telefono'] ?? '';
      _emailController.text = cliente['email'] ?? '';
      _documentoController.text = cliente['documento'] ?? '';
      _infoAdicionalController.text = cliente['info_adicional'] ?? '';
    });
  }

  void _guardarCliente() async {
    if (_clienteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el nombre del cliente')),
      );
      return;
    }
    await DatabaseHelper.instance.insertCliente({
      'nombre': _clienteController.text,
      'telefono': _telefonoController.text,
      'email': _emailController.text,
      'documento': _documentoController.text,
      'info_adicional': _infoAdicionalController.text,
    });
    await _loadClientes();
    setState(() {
      _clienteSeleccionado = {
        'id': _clientes.firstWhere(
          (c) => c['nombre'] == _clienteController.text,
          orElse: () => {'id': 0},
        )['id'],
        'nombre': _clienteController.text,
      };
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cliente guardado')));
    }
  }

  void _mostrarSelectorProductos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Seleccionar Producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: _productos.isEmpty
                  ? const Center(child: Text('No hay productos'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _productos.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.inventory, color: Colors.white),
                        ),
                        title: Text(_productos[index]['nombre']),
                        onTap: () {
                          _itemController.text = _productos[index]['nombre'];
                          Navigator.pop(context);
                        },
                      ),
                    ),
            ),
          ],
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
      body: SafeArea(
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
                              onPressed: _mostrarSelectorClientes,
                              icon: const Icon(Icons.person_search, size: 18),
                              label: const Text('Buscar'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: buildFormTextField(
                              controller: _clienteController,
                              labelText: 'Nombre',
                              prefixIcon: Icons.person,
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
                            child: buildFormTextField(
                              controller: _documentoController,
                              labelText: 'Documento',
                              prefixIcon: Icons.badge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildFormTextField(
                              controller: _telefonoController,
                              labelText: 'Teléfono',
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      buildFormTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      buildFormTextField(
                        controller: _infoAdicionalController,
                        labelText: 'Info Adicional',
                        prefixIcon: Icons.info_outline,
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
                      buildFormTextField(
                        controller: _atendidoPorController,
                        labelText: 'Atendido por',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      buildFormTextField(
                        controller: _modeloController,
                        labelText: 'Modelo',
                        prefixIcon: Icons.devices,
                      ),
                      const SizedBox(height: 12),
                      buildFormTextField(
                        controller: _serieController,
                        labelText: 'Serie',
                        prefixIcon: Icons.tag,
                      ),
                      const SizedBox(height: 12),
                      buildFormTextField(
                        controller: _estadoActualController,
                        labelText: 'Estado Actual',
                        prefixIcon: Icons.check_circle_outline,
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
                            'Productos/Servicios',
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
                                labelText: 'Item',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              if (_itemController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ingrese el nombre del producto',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await DatabaseHelper.instance.insertProducto({
                                'nombre': _itemController.text,
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
                            icon: const Icon(Icons.save, color: Colors.green),
                            tooltip: 'Guardar producto',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _precioController,
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_itemController.text.isNotEmpty &&
                                  _precioController.text.isNotEmpty) {
                                _agregarItem(
                                  _itemController.text,
                                  double.tryParse(_precioController.text) ?? 0,
                                );
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        const Center(child: Text('No hay items agregados'))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) => ListTile(
                            dense: true,
                            title: Text(_items[index]['nombre']),
                            subtitle: Text(
                              formatCOP(
                                (_items[index]['precio'] as num?)?.toDouble() ??
                                    0.0,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _items.removeAt(index)),
                            ),
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
                    children: [
                      const Text(
                        'Pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _abonoController,
                        decoration: const InputDecoration(
                          labelText: 'Abono',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
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
                            formatCOP(_total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_abono > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Abono:',
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
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Saldo:',
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _mostrarVistaPrevia,
                icon: const Icon(Icons.preview),
                label: const Text('Vista Previa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
