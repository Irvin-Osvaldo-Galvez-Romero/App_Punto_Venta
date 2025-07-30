import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/producto.dart';
import '../services/db_service.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class RegistrarProductoScreen extends StatefulWidget {
  const RegistrarProductoScreen({super.key});

  @override
  State<RegistrarProductoScreen> createState() =>
      _RegistrarProductoScreenState();
}

class _RegistrarProductoScreenState extends State<RegistrarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioCompraController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _cantidadStockController =
      TextEditingController();

  bool _editando = false;
  Producto? _productoEditando;

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _nombreController.clear();
    _precioCompraController.clear();
    _precioVentaController.clear();
    _codigoBarrasController.clear();
    _cantidadStockController.clear();
    setState(() {
      _editando = false;
      _productoEditando = null;
    });
  }

  Future<void> _guardarProducto() async {
    if (_formKey.currentState?.validate() ?? false) {
      final producto = Producto(
        id: _productoEditando?.id,
        nombre: _nombreController.text.trim(),
        precioCompra: double.parse(_precioCompraController.text),
        precioVenta: double.parse(_precioVentaController.text),
        codigoBarras: _codigoBarrasController.text.trim(),
        cantidadStock: int.parse(_cantidadStockController.text),
      );
      if (_editando && _productoEditando != null) {
        final confirmado = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar actualización'),
            content: const Text(
              '¿Estás seguro de que deseas actualizar este producto?',
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
        if (confirmado != true) return;
        await DBService.actualizarProducto(producto);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
      } else {
        await DBService.agregarProducto(producto);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto registrado')));
      }
      _limpiarFormulario();
    }
  }

  Future<void> _buscarProducto() async {
    final codigo = _codigoBarrasController.text.trim();
    final nombre = _nombreController.text.trim();
    Producto? producto;
    if (codigo.isNotEmpty) {
      producto = await DBService.buscarProductoPorCodigo(codigo);
    } else if (nombre.isNotEmpty) {
      final productos = await DBService.buscarProductosPorNombre(nombre);
      if (productos.isNotEmpty) producto = productos.first;
    }
    if (producto != null) {
      setState(() {
        _editando = true;
        _productoEditando = producto;
        _nombreController.text = producto!.nombre;
        _precioCompraController.text = producto.precioCompra.toString();
        _precioVentaController.text = producto.precioVenta.toString();
        _codigoBarrasController.text = producto.codigoBarras;
        _cantidadStockController.text = producto.cantidadStock.toString();
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto no encontrado')));
    }
  }

  Future<void> _escanearCodigoBarras() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        setState(() {
          _codigoBarrasController.text = result.rawContent;
        });
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar Producto' : 'Registrar Producto',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double buttonWidth = constraints.maxWidth;
          double buttonHeight = 56;
          double iconSize = buttonWidth * 0.07;
          double fontSize = buttonWidth * 0.045;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _editando
                              ? 'Editar Producto'
                              : 'Registrar Nuevo Producto',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Producto',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Ingrese el nombre'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _precioCompraController,
                                decoration: InputDecoration(
                                  labelText: 'Precio de Compra',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Ingrese el precio de compra'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _precioVentaController,
                                decoration: InputDecoration(
                                  labelText: 'Precio de Venta',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Ingrese el precio de venta'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _codigoBarrasController,
                                decoration: InputDecoration(
                                  labelText: 'Código de Barras',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Ingrese el código de barras'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                minimumSize: Size(buttonHeight, buttonHeight),
                              ),
                              onPressed: _escanearCodigoBarras,
                              child: Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white,
                                size: iconSize,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cantidadStockController,
                          decoration: InputDecoration(
                            labelText: 'Cantidad en Stock',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Ingrese la cantidad'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  _editando ? Icons.save : Icons.add,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                                label: Text(
                                  _editando ? 'Actualizar' : 'Registrar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  minimumSize: Size(
                                    buttonWidth * 0.4,
                                    buttonHeight,
                                  ),
                                ),
                                onPressed: _guardarProducto,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.cleaning_services,
                                  color: Colors.teal,
                                  size: iconSize,
                                ),
                                label: Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontSize: fontSize,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.teal,
                                    width: 2,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  minimumSize: Size(
                                    buttonWidth * 0.4,
                                    buttonHeight,
                                  ),
                                ),
                                onPressed: _limpiarFormulario,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: iconSize,
                          ),
                          label: Text(
                            'Buscar producto para editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            minimumSize: Size(buttonWidth * 0.8, buttonHeight),
                          ),
                          onPressed: _buscarProducto,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
