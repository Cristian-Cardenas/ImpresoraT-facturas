import 'package:flutter/material.dart';
import '../helpers/formatters.dart';

class FacturaListTile extends StatelessWidget {
  final Map<String, dynamic> factura;
  final VoidCallback onEditar;
  final VoidCallback onImprimir;

  const FacturaListTile({
    super.key,
    required this.factura,
    required this.onEditar,
    required this.onImprimir,
  });

  @override
  Widget build(BuildContext context) {
    final estado = factura['estado'] ?? 'Abierto';
    final estadoColor = estado == 'Abierto' ? Colors.orange : Colors.green;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt, color: Colors.blue),
        title: Text('Factura #${factura['numero_consecutivo']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${factura['cliente']} - ${formatCOP((factura['total'] as num?)?.toDouble() ?? 0.0)}',
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: estadoColor.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                estado,
                style: TextStyle(fontSize: 12, color: estadoColor.shade800),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: onEditar,
            ),
            IconButton(
              icon: const Icon(Icons.print, color: Colors.green),
              onPressed: onImprimir,
            ),
          ],
        ),
      ),
    );
  }
}
