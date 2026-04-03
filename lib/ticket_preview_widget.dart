import 'package:flutter/material.dart';
import 'constants.dart';

class TicketPreviewWidget extends StatelessWidget {
  final String? nombreNegocio;
  final String? nit;
  final String? direccion;
  final String? ciudad;
  final String? telefono;
  final String? correo;
  final String? logo;
  final String numeroFactura;
  final String codigoUnico;
  final String fecha;
  final String? cliente;
  final String? documento;
  final String? telefonoCliente;
  final String? correoCliente;
  final String? direccionCliente;
  final String? modelo;
  final String? serie;
  final String? estadoActual;
  final List<Map<String, dynamic>> items;
  final double total;
  final double? abono;
  final double? saldo;
  final String? mensajePie;
  final String? sitioWeb;
  final String? whatsapp;
  final String? facebook;
  final String? instagram;
  final VoidCallback? onCerrar;
  final bool showCerrar;

  const TicketPreviewWidget({
    super.key,
    this.nombreNegocio,
    this.nit,
    this.direccion,
    this.ciudad,
    this.telefono,
    this.correo,
    this.logo,
    required this.numeroFactura,
    required this.codigoUnico,
    required this.fecha,
    this.cliente,
    this.documento,
    this.telefonoCliente,
    this.correoCliente,
    this.direccionCliente,
    this.modelo,
    this.serie,
    this.estadoActual,
    required this.items,
    required this.total,
    this.abono,
    this.saldo,
    this.mensajePie,
    this.sitioWeb,
    this.whatsapp,
    this.facebook,
    this.instagram,
    this.onCerrar,
    this.showCerrar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (logo != null) const Icon(Icons.image, size: 40),
          if (nombreNegocio != null)
            Text(nombreNegocio!, style: AppTextStyles.ticketHeader),
          if (nit != null)
            Text(
              nit!,
              style: AppTextStyles.ticketBody,
              textAlign: TextAlign.center,
            ),
          if (direccion != null)
            Text(
              '$direccion${ciudad != null ? ", $ciudad" : ""}',
              style: AppTextStyles.ticketBody,
              textAlign: TextAlign.center,
            ),
          if (telefono != null)
            Text(
              'Tel: $telefono',
              style: AppTextStyles.ticketBody,
              textAlign: TextAlign.center,
            ),
          if (correo != null)
            Text(
              correo!,
              style: AppTextStyles.ticketBody,
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 8),
          Text(AppStrings.separator, style: AppTextStyles.ticketDashed),
          Text(
            '${AppStrings.factura} #$numeroFactura',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(codigoUnico, style: AppTextStyles.ticketBody),
          Text('Fecha: $fecha', style: AppTextStyles.ticketBody),

          const SizedBox(height: 8),
          Text(AppStrings.separator, style: AppTextStyles.ticketDashed),
          Text(
            AppStrings.clienteTitle,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(AppStrings.separator, style: AppTextStyles.ticketDashed),

          const SizedBox(height: 8),
          if (cliente != null)
            Text('Nombre: $cliente', style: AppTextStyles.ticketBody),
          if (documento != null)
            Text('Documento: $documento', style: AppTextStyles.ticketBody),
          if (telefonoCliente != null)
            Text('Telefono: $telefonoCliente', style: AppTextStyles.ticketBody),
          if (correoCliente != null)
            Text('Correo: $correoCliente', style: AppTextStyles.ticketBody),
          if (direccionCliente != null)
            Text(
              'Direccion: $direccionCliente',
              style: AppTextStyles.ticketBody,
            ),
          if (modelo != null)
            Text('Modelo: $modelo', style: AppTextStyles.ticketBody),
          if (serie != null)
            Text('Serie: $serie', style: AppTextStyles.ticketBody),
          if (estadoActual != null)
            Text(
              'Estado Actual: $estadoActual',
              style: AppTextStyles.ticketBody,
            ),

          const SizedBox(height: 8),
          Text(AppStrings.separator, style: AppTextStyles.ticketDashed),
          Text(
            AppStrings.productosTitle,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(AppStrings.separator, style: AppTextStyles.ticketDashed),

          ...items.map(
            (item) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['nombre'], style: AppTextStyles.ticketBody),
                Text(
                  '\$${(item['precio'] as double).toStringAsFixed(2)}',
                  style: AppTextStyles.ticketBody,
                ),
              ],
            ),
          ),

          Text(AppStrings.separator, style: AppTextStyles.ticketDashed),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.totalTitle,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          if (abono != null && abono! > 0) ...[
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
                  '- \$${abono!.toStringAsFixed(2)}',
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
                  '\$${saldo!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: saldo! > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],

          if (mensajePie != null && mensajePie!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppStrings.terminosTitle,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              mensajePie!,
              style: AppTextStyles.ticketSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],

          if (sitioWeb != null)
            Text(sitioWeb!, style: AppTextStyles.ticketSmall),
          if (whatsapp != null)
            Text('WhatsApp: $whatsapp', style: AppTextStyles.ticketSmall),
          if (facebook != null)
            Text(facebook!, style: AppTextStyles.ticketSmall),
          if (instagram != null)
            Text(instagram!, style: AppTextStyles.ticketSmall),

          const SizedBox(height: 12),
          Text(
            AppStrings.firmaCliente,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(AppStrings.firmaLinea, style: AppTextStyles.ticketBody),

          const SizedBox(height: 12),
          if (!showCerrar)
            Text(AppStrings.finTicket, style: AppTextStyles.ticketBody),
        ],
      ),
    );
  }
}
