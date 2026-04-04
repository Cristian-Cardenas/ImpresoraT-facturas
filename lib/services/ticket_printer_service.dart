import 'package:flutter/material.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import 'package:image/image.dart' as img;
import '../helpers/formatters.dart';

class TicketPrinterService {
  final PrinterManager printerManager;

  TicketPrinterService({required this.printerManager});

  Future<void> printTicketFromFactura({
    required PrinterDevice? connectedPrinter,
    required BuildContext context,
    required Map<String, dynamic> factura,
    required Map<String, dynamic>? negocio,
  }) async {
    if (connectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay impresora conectada')),
      );
      return;
    }

    try {
      final ticket = await Ticket.create(PaperSize.mm58);

      _addNegocioHeader(ticket, negocio);

      _addSeparator(ticket);

      ticket.text(
        'FACTURA #${factura['numero_consecutivo'] ?? ''}',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      if (factura['codigo_unico'] != null) {
        ticket.text(factura['codigo_unico'], align: PrintAlign.center);
      }

      String fechaStr = '';
      if (factura['fecha'] != null) {
        final fecha = factura['fecha'];
        if (fecha is DateTime) {
          fechaStr =
              '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
        } else if (fecha is String) {
          fechaStr = fecha;
        }
      }
      if (fechaStr.isNotEmpty) {
        ticket.text('Fecha: $fechaStr', align: PrintAlign.center);
      }

      _addSeparator(ticket);
      _addSectionHeader(ticket, 'CLIENTE');

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

      _addSeparator(ticket);
      _addSectionHeader(ticket, 'OTROS DATOS');

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

      _addSeparator(ticket);
      _addSectionHeader(ticket, 'PRODUCTOS Y/O SERVICIOS');

      final items = factura['items'] as List? ?? [];
      for (var item in items) {
        ticket.text('${item['nombre']}', align: PrintAlign.left);
        ticket.text(
          formatCOP((item['precio'] as num?)?.toDouble() ?? 0.0),
          align: PrintAlign.right,
        );
      }

      _addSeparator(ticket);
      final total = (factura['total'] as num?)?.toDouble() ?? 0.0;
      ticket.text(
        'TOTAL: ${formatCOP(total)}',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true, height: TextSize.size2),
      );

      final abono = (factura['abono'] as num?)?.toDouble() ?? 0.0;
      if (abono > 0) {
        final saldo = total - abono;
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

      _addNegocioFooter(ticket, negocio);

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

      await printerManager.printTicket(ticket);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al imprimir: $e')));
      rethrow;
    }
  }

  Future<void> printTicketFromControllers({
    required PrinterDevice? connectedPrinter,
    required BuildContext context,
    required Map<String, dynamic>? negocio,
    required String cliente,
    required String documento,
    required String telefono,
    required String email,
    required String infoAdicional,
    required String atendidoPor,
    required String modelo,
    required String serie,
    required String estadoActual,
    required List<Map<String, dynamic>> items,
    required double total,
    required double abono,
    required int numeroConsecutivo,
  }) async {
    if (connectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay impresora conectada')),
      );
      return;
    }

    try {
      final ticket = await Ticket.create(PaperSize.mm58);

      _addNegocioHeader(ticket, negocio);

      _addSeparator(ticket);

      ticket.text(
        'FACTURA #$numeroConsecutivo',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text('FAC-$numeroConsecutivo', align: PrintAlign.center);
      final now = DateTime.now();
      ticket.text(
        'Fecha: ${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        align: PrintAlign.center,
      );

      _addSeparator(ticket);
      _addSectionHeader(ticket, 'CLIENTE');

      if (cliente.isNotEmpty) {
        ticket.text('Nombre: $cliente', align: PrintAlign.left);
      }
      if (documento.isNotEmpty) {
        ticket.text('Documento: $documento', align: PrintAlign.left);
      }
      if (telefono.isNotEmpty) {
        ticket.text('Telefono: $telefono', align: PrintAlign.left);
      }
      if (email.isNotEmpty) {
        ticket.text('Correo: $email', align: PrintAlign.left);
      }
      if (infoAdicional.isNotEmpty) {
        ticket.text('Info Adicional: $infoAdicional', align: PrintAlign.left);
      }

      _addSeparator(ticket);
      _addSectionHeader(ticket, 'OTROS DATOS');

      if (atendidoPor.isNotEmpty) {
        ticket.text('Atendido por: $atendidoPor', align: PrintAlign.left);
      }
      if (modelo.isNotEmpty) {
        ticket.text('Modelo: $modelo', align: PrintAlign.left);
      }
      if (serie.isNotEmpty) {
        ticket.text('Serie: $serie', align: PrintAlign.left);
      }
      if (estadoActual.isNotEmpty) {
        ticket.text('Estado Actual: $estadoActual', align: PrintAlign.left);
      }

      _addSeparator(ticket);
      _addSectionHeader(ticket, 'PRODUCTOS Y/O SERVICIOS');

      for (var item in items) {
        ticket.text('${item['nombre']}', align: PrintAlign.left);
        ticket.text(
          formatCOP((item['precio'] as num?)?.toDouble() ?? 0.0),
          align: PrintAlign.right,
        );
      }

      _addSeparator(ticket);
      ticket.text(
        'TOTAL: ${formatCOP(total)}',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true, height: TextSize.size2),
      );

      if (abono > 0) {
        final saldo = total - abono;
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

      _addNegocioFooter(ticket, negocio);

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

      await printerManager.printTicket(ticket);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al imprimir: $e')));
      rethrow;
    }
  }

  void _addNegocioHeader(Ticket ticket, Map<String, dynamic>? negocio) {
    if (negocio == null) return;

    if (negocio['logo'] != null) {
      try {
        ticket.image(negocio['logo'] as img.Image, align: PrintAlign.center);
      } catch (e) {
        debugPrint('Error printing logo: $e');
      }
    }
    if (negocio['nombre'] != null && negocio['nombre'].isNotEmpty) {
      ticket.text(
        negocio['nombre'],
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
    }
    if (negocio['nit'] != null && negocio['nit'].isNotEmpty) {
      ticket.text(negocio['nit'], align: PrintAlign.center);
    }
    if (negocio['direccion'] != null && negocio['direccion'].isNotEmpty) {
      String dir = negocio['direccion'];
      if (negocio['ciudad'] != null && negocio['ciudad'].isNotEmpty) {
        dir += ', ${negocio['ciudad']}';
      }
      ticket.text(dir, align: PrintAlign.center);
    }
    if (negocio['telefono1'] != null && negocio['telefono1'].isNotEmpty) {
      ticket.text('Tel: ${negocio['telefono1']}', align: PrintAlign.center);
    }
    if (negocio['correo'] != null && negocio['correo'].isNotEmpty) {
      ticket.text(negocio['correo'], align: PrintAlign.center);
    }
  }

  void _addNegocioFooter(Ticket ticket, Map<String, dynamic>? negocio) {
    if (negocio == null) return;

    if (negocio['mensaje_pie'] != null && negocio['mensaje_pie'].isNotEmpty) {
      ticket.text(
        'TERMINOS Y CONDICIONES',
        align: PrintAlign.center,
        style: const PrintTextStyle(bold: true),
      );
      ticket.text(negocio['mensaje_pie'], align: PrintAlign.center);
    }
    if (negocio['sitio_web'] != null && negocio['sitio_web'].isNotEmpty) {
      ticket.text(negocio['sitio_web'], align: PrintAlign.center);
    }
    if (negocio['whatsapp'] != null && negocio['whatsapp'].isNotEmpty) {
      ticket.text('WhatsApp: ${negocio['whatsapp']}', align: PrintAlign.center);
    }
    if (negocio['facebook'] != null && negocio['facebook'].isNotEmpty) {
      ticket.text(negocio['facebook'], align: PrintAlign.center);
    }
    if (negocio['instagram'] != null && negocio['instagram'].isNotEmpty) {
      ticket.text(negocio['instagram'], align: PrintAlign.center);
    }
  }

  void _addSeparator(Ticket ticket) {
    ticket.text('================================', align: PrintAlign.center);
  }

  void _addSectionHeader(Ticket ticket, String title) {
    ticket.text(
      title,
      align: PrintAlign.center,
      style: const PrintTextStyle(bold: true),
    );
    _addSeparator(ticket);
  }
}
