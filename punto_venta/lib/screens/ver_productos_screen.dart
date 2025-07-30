import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/producto.dart';
import '../services/db_service.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class VerProductosScreen extends StatefulWidget {
  const VerProductosScreen({super.key});

  @override
  State<VerProductosScreen> createState() => _VerProductosScreenState();
}

class _VerProductosScreenState extends State<VerProductosScreen> {
  List<Producto> _productos = [];
  String _busqueda = '';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargando = true);
    List<Producto> productos = [];
    if (_busqueda.isEmpty) {
      productos = await DBService.obtenerProductos();
    } else if (RegExp(r'^[0-9]{6,}\$').hasMatch(_busqueda)) {
      // Si es un código de barras (numérico y largo)
      final prod = await DBService.buscarProductoPorCodigo(_busqueda);
      if (prod != null) productos = [prod];
    } else {
      productos = await DBService.buscarProductosPorNombre(_busqueda);
    }
    setState(() {
      _productos = productos;
      _cargando = false;
    });
  }

  Future<void> _eliminarProducto(int id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este producto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await DBService.eliminarProducto(id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      _cargarProductos();
    }
  }

  Future<void> _escanearCodigoBarras() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        setState(() {
          _busqueda = result.rawContent;
        });
        _cargarProductos();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo escanear el código de barras'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Ver Productos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double iconSize = constraints.maxWidth * 0.07;
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Buscar producto',
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurface,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.qr_code_scanner,
                              color: theme.colorScheme.onSurface,
                            ),
                            tooltip: 'Escanear',
                            onPressed: _escanearCodigoBarras,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _busqueda = value);
                          _cargarProductos();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _cargando
                          ? const Center(child: CircularProgressIndicator())
                          : _productos.isEmpty
                          ? Center(
                              child: Text(
                                'No hay productos registrados',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _productos.length,
                              itemBuilder: (context, index) {
                                final producto = _productos[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Slidable(
                                    key: ValueKey(producto.id),
                                    endActionPane: ActionPane(
                                      motion: const DrawerMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (_) =>
                                              _eliminarProducto(producto.id!),
                                          icon: Icons.delete,
                                          label: 'Eliminar',
                                          backgroundColor: Colors.red,
                                        ),
                                      ],
                                    ),
                                    child: Card(
                                      elevation: 6,
                                      color: theme.cardColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue[100],
                                          child: Icon(
                                            Icons.inventory_2,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                        title: Text(
                                          producto.nombre,
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Stock: ${producto.cantidadStock}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              'Compra: ${producto.precioCompra} | Venta: ${producto.precioVenta}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              producto.codigoBarras,
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 13,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: iconSize,
                                              ),
                                              tooltip: 'Eliminar',
                                              onPressed: () =>
                                                  _eliminarProducto(
                                                    producto.id!,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
