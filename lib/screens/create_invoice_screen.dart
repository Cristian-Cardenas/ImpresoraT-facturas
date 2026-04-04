import 'package:flutter/material.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../database_helper.dart';
import '../helpers/formatters.dart';
import '../widgets/factura_preview_widget.dart';

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
    setState(() => _clientes = clientes);
  }

  Future<void> _loadProductos() async {
    final productos = await DatabaseHelper.instance.getProductos();
    setState(() => _productos = productos);
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
      setState(() => _status = 'No hay impresora conectada');
      return;
    }
    setState(() {
      _isPrinting = true;
      _status = 'Imprimiendo...';
    });
    try {
      final numeroConsecutivo =
          await widget.getSiguienteConsecutivo?.call() ?? 1;
      final codigoUnico = 'FAC-$numeroConsecutivo';
      final facturaData = {
        'numero_consecutivo': numeroConsecutivo,
        'codigo_unico': codigoUnico,
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
        'estado': _saldo > 0 ? 'Adeudo' : 'Pagado',
        'atendido_por': _atendidoPorController.text,
        'modelo': _modeloController.text,
        'serie': _serieController.text,
        'estado_actual': _estadoActualController.text,
      };
      final negocio = widget.negocio;
      final ticket = await Ticket.create(PaperSize.mm58);
      if (negocio != null && negocio['logo'] != null) {
        try {
          ticket.image(negocio['logo'] as img.Image, align: PrintAlign.center);
        } catch (e) {
          debugPrint('Error printing logo: $e');
        }
      }
      if (negocio != null &&
          negocio['nombre'] != null &&
          negocio['nombre'].isNotEmpty)
        ticket.text(
          negocio['nombre'],
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
      if (negocio != null &&
          negocio['nit'] != null &&
          negocio['nit'].isNotEmpty)
        ticket.text(negocio['nit'], align: PrintAlign.center);
      if (negocio != null &&
          negocio['direccion'] != null &&
          negocio['direccion'].isNotEmpty)
        ticket.text(
          '${negocio['direccion']}${negocio['ciudad'] != null ? ", ${negocio['ciudad']}" : ""}',
          align: PrintAlign.center,
        );
      if (negocio != null &&
          negocio['telefono1'] != null &&
          negocio['telefono1'].isNotEmpty)
        ticket.text('Tel: ${negocio['telefono1']}', align: PrintAlign.center);
      if (negocio != null &&
          negocio['correo'] != null &&
          negocio['correo'].isNotEmpty)
        ticket.text(negocio['correo'], align: PrintAlign.center);
      ticket.text('================================', align: PrintAlign.center);
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
      ticket.text('================================', align: PrintAlign.center);
      ticket.text(
        'OTROS DATOS',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('================================', align: PrintAlign.center);
      if (_atendidoPorController.text.isNotEmpty)
        ticket.text(
          'Atendido por: ${_atendidoPorController.text}',
          align: PrintAlign.left,
        );
      if (_modeloController.text.isNotEmpty)
        ticket.text(
          'Modelo: ${_modeloController.text}',
          align: PrintAlign.left,
        );
      if (_serieController.text.isNotEmpty)
        ticket.text('Serie: ${_serieController.text}', align: PrintAlign.left);
      if (_estadoActualController.text.isNotEmpty)
        ticket.text(
          'Estado Actual: ${_estadoActualController.text}',
          align: PrintAlign.left,
        );
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
          formatCOP((item['precio'] as num?)?.toDouble() ?? 0.0),
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
      widget.onFacturaCreada?.call(facturaData);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                    const Text(
                      'Datos del Cliente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const Text(
                      'Productos/Servicios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                        SizedBox(
                          width: 120,
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
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
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _mostrarSelectorProductos(),
                          icon: const Icon(Icons.list),
                          label: const Text('Buscar'),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _imprimirFactura,
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
                    label: Text(_isPrinting ? 'Imprimiendo...' : 'Imprimir'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _guardarSinImprimir,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
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

  void _guardarCliente() async {
    if (_clienteController.text.isEmpty) return;
    await DatabaseHelper.instance.insertCliente({
      'nombre': _clienteController.text,
      'telefono': _telefonoController.text,
      'email': _emailController.text,
      'documento': _documentoController.text,
      'info_adicional': _infoAdicionalController.text,
    });
    await _loadClientes();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cliente guardado')));
  }

  void _guardarSinImprimir() async {
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
    final factura = {
      'numero_consecutivo': numeroConsecutivo,
      'codigo_unico': 'FAC-$numeroConsecutivo',
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
      'estado': _saldo > 0 ? 'Adeudo' : 'Pagado',
      'atendido_por': _atendidoPorController.text,
      'modelo': _modeloController.text,
      'serie': _serieController.text,
      'estado_actual': _estadoActualController.text,
    };
    widget.onFacturaCreada?.call(factura);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Factura guardada')));
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
                          _agregarItem(
                            _productos[index]['nombre'],
                            (_productos[index]['precio'] as num?)?.toDouble() ??
                                0.0,
                          );
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
}
