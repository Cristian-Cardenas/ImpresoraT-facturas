import 'package:flutter/material.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import '../database_helper.dart';
import '../helpers/formatters.dart';
import '../widgets/factura_list_tile.dart';
import '../widgets/factura_preview_widget.dart';

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
  Key _listKey = UniqueKey();

  void _refreshFacturas() async {
    final facturas = await DatabaseHelper.instance.getFacturas();
    widget.facturas.clear();
    widget.facturas.addAll(facturas);
    setState(() {
      _listKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedFacturas = widget.facturas;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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

      final abono = (factura['abono'] as num?)?.toDouble() ?? 0.0;
      if (abono > 0) {
        final saldo = (factura['total'] as double) - abono;
        ticket.text(
          'ABONO: -${formatCOP(abono)}',
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
        ticket.text(
          'SALDO: ${formatCOP(saldo)}',
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

  String _formatFecha(dynamic fecha) {
    if (fecha is DateTime) return '${fecha.day}/${fecha.month}/${fecha.year}';
    if (fecha is String) return fecha;
    return '';
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
}
