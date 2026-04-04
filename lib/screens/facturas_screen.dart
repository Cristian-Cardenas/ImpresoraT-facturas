import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../helpers/formatters.dart';
import '../widgets/factura_list_tile.dart';
import '../widgets/factura_preview_widget.dart';
import '../services/ticket_printer_service.dart';

class FacturasScreen extends StatefulWidget {
  final dynamic printerManager;
  final dynamic connectedPrinter;
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
  late final TicketPrinterService _printerService;
  Key _listKey = UniqueKey();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredFacturas = [];

  @override
  void initState() {
    super.initState();
    _printerService = TicketPrinterService(
      printerManager: widget.printerManager,
    );
    _filteredFacturas = widget.facturas;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFacturas(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFacturas = widget.facturas;
      } else {
        _filteredFacturas = widget.facturas.where((f) {
          final cliente = (f['cliente'] ?? '').toLowerCase();
          final numero = (f['numero_consecutivo'] ?? '').toString();
          final codigo = (f['codigo_unico'] ?? '').toLowerCase();
          final estado = (f['estado'] ?? '').toLowerCase();
          final search = query.toLowerCase();
          return cliente.contains(search) ||
              numero.contains(search) ||
              codigo.contains(search) ||
              estado.contains(search);
        }).toList();
      }
    });
  }

  void _refreshFacturas() async {
    final facturas = await DatabaseHelper.instance.getFacturas();
    widget.facturas.clear();
    widget.facturas.addAll(facturas);
    setState(() {
      _filteredFacturas = List.from(widget.facturas);
      _listKey = UniqueKey();
    });
  }

  Future<void> _imprimirFactura(Map<String, dynamic> factura) async {
    await _printerService.printTicketFromFactura(
      connectedPrinter: widget.connectedPrinter,
      context: context,
      factura: factura,
      negocio: widget.negocio,
    );
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
                FacturaPreviewWidget(
                  factura: factura,
                  negocio: widget.negocio,
                  onImprimir: () {
                    Navigator.pop(context);
                    _imprimirFactura(factura);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editarFactura(int index, Map<String, dynamic> factura) {
    final items = List<Map<String, dynamic>>.from(factura['items']);
    String estado = factura['estado'] ?? 'Debe';

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              factura['cliente'] ?? 'Sin cliente',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.receipt, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Factura #${factura['numero_consecutivo']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...items.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['nombre'] ?? ''),
                    subtitle: Text(
                      formatCOP((item['precio'] as num?)?.toDouble() ?? 0.0),
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
                      formatCOP((factura['total'] as num?)?.toDouble() ?? 0.0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Builder(
                  builder: (context) {
                    final abono = (factura['abono'] as num?)?.toDouble() ?? 0.0;
                    if (abono > 0) {
                      final saldo =
                          ((factura['total'] as num?)?.toDouble() ?? 0.0) -
                          abono;
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Abono:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '-${formatCOP(abono)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatCOP(saldo),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: saldo > 0 ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estado:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Debe',
                      label: Text('Debe'),
                      icon: Icon(Icons.warning_amber_rounded),
                    ),
                    ButtonSegment(
                      value: 'Pagado',
                      label: Text('Pagado'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {estado},
                  onSelectionChanged: (newSelection) {
                    setModalState(() => estado = newSelection.first);
                  },
                  selectedIcon: const Icon(Icons.check),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return estado == 'Debe' ? Colors.red : Colors.green;
                      }
                      return Colors.grey.shade200;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.grey.shade700;
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final updatedFactura = {...factura, 'estado': estado};
                    widget.onFacturaActualizada?.call(index, updatedFactura);
                    Navigator.pop(context);
                    _refreshFacturas();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas'),
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
                hintText: 'Buscar facturas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _filterFacturas,
            ),
          ),
          Expanded(
            child: _filteredFacturas.isEmpty
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
                          _searchController.text.isEmpty
                              ? 'No hay facturas creadas'
                              : 'No se encontraron facturas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_searchController.text.isEmpty)
                          Text(
                            'Crea una factura en "Crear Factura"',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    key: _listKey,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFacturas.length,
                    itemBuilder: (context, index) {
                      final factura = _filteredFacturas[index];
                      final originalIndex = widget.facturas.indexWhere(
                        (f) => f['id'] == factura['id'],
                      );
                      return FacturaListTile(
                        factura: factura,
                        onEditar: () => _editarFactura(
                          originalIndex >= 0 ? originalIndex : index,
                          factura,
                        ),
                        onImprimir: () => _mostrarVistaPrevia(factura),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
