import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../helpers/formatters.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _filteredClientes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClientes() async {
    final clientes = await DatabaseHelper.instance.getClientes();
    setState(() {
      _clientes = clientes;
      _filteredClientes = clientes;
      _isLoading = false;
    });
  }

  void _filterClientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClientes = _clientes;
      } else {
        _filteredClientes = _clientes.where((c) {
          final nombre = (c['nombre'] ?? '').toLowerCase();
          final documento = (c['documento'] ?? '').toLowerCase();
          final telefono = (c['telefono'] ?? '').toLowerCase();
          final search = query.toLowerCase();
          return nombre.contains(search) ||
              documento.contains(search) ||
              telefono.contains(search);
        }).toList();
      }
    });
  }

  void _mostrarEditarCliente(Map<String, dynamic> cliente) {
    final nombreController = TextEditingController(text: cliente['nombre']);
    final telefonoController = TextEditingController(
      text: cliente['telefono'] ?? '',
    );
    final emailController = TextEditingController(text: cliente['email'] ?? '');
    final documentoController = TextEditingController(
      text: cliente['documento'] ?? '',
    );
    final infoController = TextEditingController(
      text: cliente['info_adicional'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Editar Cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: documentoController,
                  labelText: 'Documento',
                  prefixIcon: Icons.badge,
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: telefonoController,
                  labelText: 'Teléfono',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: infoController,
                  labelText: 'Info Adicional',
                  prefixIcon: Icons.info_outline,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await DatabaseHelper.instance.insertCliente({
                      'nombre': nombreController.text,
                      'telefono': telefonoController.text,
                      'email': emailController.text,
                      'documento': documentoController.text,
                      'info_adicional': infoController.text,
                    });
                    await _loadClientes();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cliente actualizado')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Guardar'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarAgregarCliente() {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    final emailController = TextEditingController();
    final documentoController = TextEditingController();
    final infoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Agregar Cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: documentoController,
                  labelText: 'Documento',
                  prefixIcon: Icons.badge,
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: telefonoController,
                  labelText: 'Teléfono',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                buildFormTextField(
                  controller: infoController,
                  labelText: 'Info Adicional',
                  prefixIcon: Icons.info_outline,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ingrese el nombre del cliente'),
                        ),
                      );
                      return;
                    }
                    await DatabaseHelper.instance.insertCliente({
                      'nombre': nombreController.text,
                      'telefono': telefonoController.text,
                      'email': emailController.text,
                      'documento': documentoController.text,
                      'info_adicional': infoController.text,
                    });
                    await _loadClientes();
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cliente guardado')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Guardar'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _eliminarCliente(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Estás seguro de eliminar a "${cliente['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteCliente(cliente['id']);
              await _loadClientes();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente eliminado')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarAgregarCliente,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar clientes...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: _filterClientes,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredClientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No hay clientes registrados'
                                : 'No se encontraron clientes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredClientes.length,
                      itemBuilder: (context, index) {
                        final cliente = _filteredClientes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (cliente['nombre'] ?? '')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                            ),
                            title: Text(cliente['nombre'] ?? ''),
                            subtitle: Text(
                              '${cliente['telefono'] ?? ''} ${cliente['documento'] != null && cliente['documento'].isNotEmpty ? '- ${cliente['documento']}' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () =>
                                      _mostrarEditarCliente(cliente),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _eliminarCliente(cliente),
                                ),
                              ],
                            ),
                            onTap: () => _mostrarEditarCliente(cliente),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
