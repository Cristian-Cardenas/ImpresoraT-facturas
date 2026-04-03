import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF1976D2);
  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFC62828);
  static const warning = Color(0xFFF57C00);
}

class AppTextStyles {
  static const ticketHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );
  static const ticketSection = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );
  static const ticketBody = TextStyle(fontSize: 10);
  static const ticketSmall = TextStyle(fontSize: 9);
  static const ticketDashed = TextStyle(fontSize: 10);
  static const cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const total = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
}

class AppDimens {
  static const double ticketWidth = 280.0;
  static const double iconSize = 40.0;
  static const double padding = 12.0;
  static const double margin = 8.0;
  static const double spacing = 16.0;
}

class AppFormats {
  static const String currencyPrefix = 'L ';
  static const String currencyFormat = 'L \${amount}';
}

class AppStrings {
  static const appName = 'Impresora de Facturas';
  static const factura = 'FACTURA';
  static const clienteTitle = 'CLIENTE';
  static const productosTitle = 'PRODUCTOS Y/O SERVICIOS';
  static const totalTitle = 'TOTAL:';
  static const terminosTitle = 'TERMINOS Y CONDICIONES';
  static const firmaCliente = 'FIRMA DEL CLIENTE';
  static const firmaLinea = '________________________';
  static const finTicket = '*** FIN DEL TICKET ***';
  static const graciasPorSuCompra = '*** GRACIAS POR SU COMPRA ***';
  static const separator = '================================';
  static const separatorShort = '-----------------------------';
}
