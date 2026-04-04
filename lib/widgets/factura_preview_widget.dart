import 'package:flutter/material.dart';
import '../helpers/formatters.dart';

class FacturaPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> factura;
  final Map<String, dynamic>? negocio;
  final VoidCallback? onImprimir;
  final bool showButtons;

  const FacturaPreviewWidget({
    super.key,
    required this.factura,
    this.negocio,
    this.onImprimir,
    this.showButtons = true,
  });

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '';
    if (fecha is DateTime) {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
    if (fecha is String) {
      return fecha;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final items = factura['items'] as List? ?? [];
    final total = (factura['total'] as num?)?.toDouble() ?? 0.0;
    final abono = (factura['abono'] as num?)?.toDouble() ?? 0.0;
    final saldo = total - abono;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 280.0;
        return Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (negocio != null && negocio!['logo'] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: const Icon(Icons.image, size: 40),
                ),
              if (negocio != null &&
                  negocio!['nombre'] != null &&
                  negocio!['nombre'].toString().isNotEmpty)
                Text(
                  negocio!['nombre'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (negocio != null &&
                  negocio!['nit'] != null &&
                  negocio!['nit'].toString().isNotEmpty)
                Text(
                  negocio!['nit'],
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              if (negocio != null &&
                  negocio!['direccion'] != null &&
                  negocio!['direccion'].toString().isNotEmpty)
                Text(
                  '${negocio!['direccion']}${negocio!['ciudad'] != null && negocio!['ciudad'].toString().isNotEmpty ? ", ${negocio!['ciudad']}" : ""}',
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              if (negocio != null &&
                  negocio!['telefono1'] != null &&
                  negocio!['telefono1'].toString().isNotEmpty)
                Text(
                  'Tel: ${negocio!['telefono1']}',
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              if (negocio != null &&
                  negocio!['correo'] != null &&
                  negocio!['correo'].toString().isNotEmpty)
                Text(
                  negocio!['correo'],
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              const Text(
                '================================',
                style: TextStyle(fontSize: 10),
              ),
              Text(
                'FACTURA #${factura['numero_consecutivo'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                factura['codigo_unico'] ?? '',
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                'Fecha: ${_formatFecha(factura['fecha'])}',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 8),
              const Text(
                '================================',
                style: TextStyle(fontSize: 10),
              ),
              const Text(
                'CLIENTE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const Text(
                '================================',
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 8),
              if (factura['cliente'] != null &&
                  factura['cliente'].toString().isNotEmpty)
                Text(
                  'Nombre: ${factura['cliente']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['documento'] != null &&
                  factura['documento'].toString().isNotEmpty)
                Text(
                  'Documento: ${factura['documento']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['telefono'] != null &&
                  factura['telefono'].toString().isNotEmpty)
                Text(
                  'Telefono: ${factura['telefono']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['email'] != null &&
                  factura['email'].toString().isNotEmpty)
                Text(
                  'Correo: ${factura['email']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['info_adicional'] != null &&
                  factura['info_adicional'].toString().isNotEmpty)
                Text(
                  'Info Adicional: ${factura['info_adicional']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['direccion'] != null &&
                  factura['direccion'].toString().isNotEmpty)
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const Text(
                '================================',
                style: TextStyle(fontSize: 10),
              ),
              if (factura['atendido_por'] != null &&
                  factura['atendido_por'].toString().isNotEmpty)
                Text(
                  'Atendido por: ${factura['atendido_por']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['modelo'] != null &&
                  factura['modelo'].toString().isNotEmpty)
                Text(
                  'Modelo: ${factura['modelo']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['serie'] != null &&
                  factura['serie'].toString().isNotEmpty)
                Text(
                  'Serie: ${factura['serie']}',
                  style: const TextStyle(fontSize: 10),
                ),
              if (factura['estado_actual'] != null &&
                  factura['estado_actual'].toString().isNotEmpty)
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const Text(
                '================================',
                style: TextStyle(fontSize: 10),
              ),
              ...items.map(
                (item) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['nombre'] ?? '',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      formatCOP((item['precio'] as num?)?.toDouble() ?? 0.0),
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
                    formatCOP(total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (abono > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ABONO:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      '-${formatCOP(abono)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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
                      formatCOP(saldo),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              if (negocio != null &&
                  negocio!['mensaje_pie'] != null &&
                  negocio!['mensaje_pie'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'TERMINOS Y CONDICIONES',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  negocio!['mensaje_pie'],
                  style: const TextStyle(fontSize: 9),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              if (negocio != null &&
                  negocio!['sitio_web'] != null &&
                  negocio!['sitio_web'].toString().isNotEmpty)
                Text(
                  negocio!['sitio_web'],
                  style: const TextStyle(fontSize: 9),
                ),
              if (negocio != null &&
                  negocio!['whatsapp'] != null &&
                  negocio!['whatsapp'].toString().isNotEmpty)
                Text(
                  'WhatsApp: ${negocio!['whatsapp']}',
                  style: const TextStyle(fontSize: 9),
                ),
              if (negocio != null &&
                  negocio!['facebook'] != null &&
                  negocio!['facebook'].toString().isNotEmpty)
                Text(negocio!['facebook'], style: const TextStyle(fontSize: 9)),
              if (negocio != null &&
                  negocio!['instagram'] != null &&
                  negocio!['instagram'].toString().isNotEmpty)
                Text(
                  negocio!['instagram'],
                  style: const TextStyle(fontSize: 9),
                ),
              const SizedBox(height: 12),
              const Text(
                'FIRMA DEL CLIENTE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                '________________________',
                style: TextStyle(fontSize: 10),
              ),
              if (showButtons && onImprimir != null) ...[
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
                        onPressed: onImprimir,
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
            ],
          ),
        );
      },
    );
  }
}
