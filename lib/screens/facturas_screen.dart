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

  @override
  void initState() {
    super.initState();
    _printerService = TicketPrinterService(
      printerManager: widget.printerManager,
    );
  }

  void _refreshFacturas() async {
    final facturas = await DatabaseHelper.instance.getFacturas();
    widget.facturas.clear();
    widget.facturas.addAll(facturas);
    setState(() {
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
                    ButtonSegment(value: 'Abierto', label: Text('Abierto')),
                    ButtonSegment(value: 'Cerrado', label: Text('Cerrado')),
                    ButtonSegment(value: 'Adeudo', label: Text('Adeudo')),
                    ButtonSegment(value: 'Pagado', label: Text('Pagado')),
                  ],
                  selected: {estado},
                  onSelectionChanged: (newSelection) {
                    setModalState(() => estado = newSelection.first);
                  },
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
    final displayedFacturas = widget.facturas;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturas'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: displayedFacturas.isEmpty
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
              key: _listKey,
              padding: const EdgeInsets.all(16),
              itemCount: displayedFacturas.length,
              itemBuilder: (context, index) {
                final factura = displayedFacturas[index];
                return FacturaListTile(
                  factura: factura,
                  onEditar: () => _editarFactura(index, factura),
                  onImprimir: () => _mostrarVistaPrevia(factura),
                );
              },
            ),
    );
  }
}
