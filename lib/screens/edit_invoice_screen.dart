import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';
import '../database_helper.dart';
import '../image_helper.dart';

class EditInvoiceScreen extends StatefulWidget {
  final PrinterManager printerManager;
  final PrinterDevice? connectedPrinter;

  const EditInvoiceScreen({
    super.key,
    required this.printerManager,
    this.connectedPrinter,
  });

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  img.Image? _logoImageProcessed;
  final TextEditingController _nombreNegocioController = TextEditingController(
    text: 'Mi Negocio',
  );
  final TextEditingController _nitController = TextEditingController(
    text: 'NIT: 123456789',
  );
  final TextEditingController _direccionController = TextEditingController(
    text: 'Calle Principal 123',
  );
  final TextEditingController _ciudadController = TextEditingController(
    text: 'Ciudad',
  );
  final TextEditingController _codigoPostalController = TextEditingController(
    text: '01000',
  );
  final TextEditingController _correoController = TextEditingController(
    text: 'correo@negocio.com',
  );
  final TextEditingController _telefono1Controller = TextEditingController(
    text: '12345678',
  );
  final TextEditingController _telefono2Controller = TextEditingController(
    text: '87654321',
  );
  late String _numeroConsecutivo;
  late String _codigoUnico;
  late DateTime _fechaActual;
  bool _isLoadingConsecutivo = true;
  final TextEditingController _mensajePieController = TextEditingController(
    text: 'Aqui van los terminos y condiciones de los productos y servicios.',
  );
  final TextEditingController _sitioWebController = TextEditingController(
    text: 'www.minegocio.com',
  );
  final TextEditingController _facebookController = TextEditingController(
    text: '@miFacebook',
  );
  final TextEditingController _instagramController = TextEditingController(
    text: '@miInstagram',
  );
  final TextEditingController _whatsappController = TextEditingController(
    text: '+504 12345678',
  );
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fechaActual = DateTime.now();
    _loadNegocio();
    _loadConsecutivo();
  }

  Future<void> _loadConsecutivo() async {
    final siguiente = await DatabaseHelper.instance.getSiguienteConsecutivo();
    if (mounted) {
      setState(() {
        _numeroConsecutivo = siguiente.toString();
        _codigoUnico = 'FAC-$siguiente';
        _isLoadingConsecutivo = false;
      });
    }
  }

  Future<void> _loadNegocio() async {
    final negocio = await DatabaseHelper.instance.getNegocio();
    if (negocio != null && mounted) {
      setState(() {
        if (negocio['logo'] != null) _logoImageProcessed = negocio['logo'];
        _nombreNegocioController.text = negocio['nombre'] ?? '';
        _nitController.text = negocio['nit'] ?? '';
        _direccionController.text = negocio['direccion'] ?? '';
        _ciudadController.text = negocio['ciudad'] ?? '';
        _codigoPostalController.text = negocio['codigo_postal'] ?? '';
        _correoController.text = negocio['correo'] ?? '';
        _telefono1Controller.text = negocio['telefono1'] ?? '';
        _telefono2Controller.text = negocio['telefono2'] ?? '';
        _sitioWebController.text = negocio['sitio_web'] ?? '';
        _facebookController.text = negocio['facebook'] ?? '';
        _instagramController.text = negocio['instagram'] ?? '';
        _whatsappController.text = negocio['whatsapp'] ?? '';
        _mensajePieController.text = negocio['mensaje_pie'] ?? '';
      });
    }
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      await DatabaseHelper.instance.saveNegocio({
        'logo': _logoImageProcessed,
        'nombre': _nombreNegocioController.text,
        'nit': _nitController.text,
        'direccion': _direccionController.text,
        'ciudad': _ciudadController.text,
        'codigo_postal': _codigoPostalController.text,
        'correo': _correoController.text,
        'telefono1': _telefono1Controller.text,
        'telefono2': _telefono2Controller.text,
        'sitio_web': _sitioWebController.text,
        'facebook': _facebookController.text,
        'instagram': _instagramController.text,
        'whatsapp': _whatsappController.text,
        'mensaje_pie': _mensajePieController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
      }
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final processedImage = await ImageHelper.procesarLogo(bytes);
        setState(() => _logoImageProcessed = processedImage);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Editar Plantilla'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _guardar),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                        const Text(
                          'Logo del Negocio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: _seleccionarImagen,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: _logoImageProcessed != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        Uint8List.fromList(
                                          img.encodePng(_logoImageProcessed!),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Toca para subir logo',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'La imagen se imprimirá centrada al inicio de la factura',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
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
                          'Información del Negocio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombreNegocioController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Negocio',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nitController,
                          decoration: const InputDecoration(
                            labelText: 'NIT / Identificación',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _ciudadController,
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) =>
                                    value!.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _codigoPostalController,
                                decoration: const InputDecoration(
                                  labelText: 'Cod.Postal',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _correoController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _telefono1Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono 1',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _telefono2Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono 2',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_android),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
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
                          'Datos de Facturación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingConsecutivo)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          TextFormField(
                            initialValue: _numeroConsecutivo,
                            decoration: const InputDecoration(
                              labelText: 'Próximo Número (Ejemplo)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _codigoUnico,
                            decoration: const InputDecoration(
                              labelText: 'Código Único (Ejemplo)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.qr_code),
                            ),
                            readOnly: true,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue:
                              '${_fechaActual.day}/${_fechaActual.month}/${_fechaActual.year}',
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Emisión',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
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
                          'Redes Sociales',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sitioWebController,
                          decoration: const InputDecoration(
                            labelText: 'Sitio Web',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _facebookController,
                          decoration: const InputDecoration(
                            labelText: 'Facebook',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.facebook),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _instagramController,
                          decoration: const InputDecoration(
                            labelText: 'Instagram',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.camera_alt),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _whatsappController,
                          decoration: const InputDecoration(
                            labelText: 'WhatsApp',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.chat),
                          ),
                          keyboardType: TextInputType.phone,
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
                          'Terminos y Condiciones',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mensajePieController,
                          decoration: const InputDecoration(
                            labelText: 'Terminos y condiciones',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.message),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Configuración'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
