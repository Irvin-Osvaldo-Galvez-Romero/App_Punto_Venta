import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../services/db_service.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class ProcesarVentasScreen extends StatefulWidget {
  const ProcesarVentasScreen({super.key});

  @override
  State<ProcesarVentasScreen> createState() => _ProcesarVentasScreenState();
}

class _ProcesarVentasScreenState extends State<ProcesarVentasScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  final List<ProductoVendido> _productosVenta = [];
  Producto? _productoSeleccionado;
  int _cantidad = 1;
  double _total = 0.0;
  bool _buscando = false;

  void _calcularTotal() {
    _total = _productosVenta.fold(
      0.0,
      (sum, p) => sum + (p.precioVenta * p.cantidad),
    );
    setState(() {});
  }

  Future<void> _buscarProducto() async {
    setState(() => _buscando = true);
    final query = _busquedaController.text.trim();
    Producto? producto;
    if (query.isEmpty) {
      setState(() {
        _productoSeleccionado = null;
        _buscando = false;
      });
      return;
    }
    if (RegExp(r'^[0-9]+$').hasMatch(query)) {
      producto = await DBService.buscarProductoPorCodigo(query);
    } else {
      final productos = await DBService.buscarProductosPorNombre(query);
      if (productos.isNotEmpty) producto = productos.first;
    }
    setState(() {
      _productoSeleccionado = producto;
      _buscando = false;
    });
    if (producto == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto no encontrado')));
    }
  }

  void _agregarProductoAVenta() {
    if (_productoSeleccionado == null) return;
    final existente = _productosVenta.indexWhere(
      (p) => p.productoId == _productoSeleccionado!.id,
    );
    if (existente >= 0) {
      _productosVenta[existente].cantidad += _cantidad;
    } else {
      _productosVenta.add(
        ProductoVendido(
          productoId: _productoSeleccionado!.id!,
          nombre: _productoSeleccionado!.nombre,
          precioCompra: _productoSeleccionado!.precioCompra,
          precioVenta: _productoSeleccionado!.precioVenta,
          cantidad: _cantidad,
        ),
      );
    }
    _productoSeleccionado = null;
    _busquedaController.clear();
    _cantidad = 1;
    _calcularTotal();
  }

  void _eliminarProductoDeVenta(int index) {
    _productosVenta.removeAt(index);
    _calcularTotal();
  }

  Future<void> _registrarVenta() async {
    if (_productosVenta.isEmpty) return;
    final venta = Venta(
      fecha: DateTime.now(),
      productosVendidos: List.from(_productosVenta),
      total: _total,
    );
    await DBService.registrarVenta(venta);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Venta registrada')));
    _productosVenta.clear();
    _calcularTotal();
    setState(() {});
  }

  Future<void> _escanearCodigoBarras() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        _busquedaController.text = result.rawContent;
        _buscarProducto();
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
        title: const Text(
          'Procesar Venta',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
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
            padding: const EdgeInsets.all(16),
            child: ListView(
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
                    controller: _busquedaController,
                    decoration: InputDecoration(
                      labelText: 'Buscar producto (nombre o código de barras)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.qr_code_scanner, size: iconSize),
                        tooltip: 'Escanear',
                        onPressed: _escanearCodigoBarras,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _buscarProducto(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_buscando) const LinearProgressIndicator(),
                if (_productoSeleccionado != null) ...[
                  Card(
                    color: Colors.grey[100],
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange[100],
                        child: Icon(
                          Icons.qr_code,
                          color: Colors.orange[800],
                          size: iconSize,
                        ),
                      ),
                      title: Text(
                        _productoSeleccionado!.nombre,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Stock: ${_productoSeleccionado!.cantidadStock} | Venta: ${_productoSeleccionado!.precioVenta}',
                      ),
                      trailing: Text(
                        _productoSeleccionado!.codigoBarras,
                        style: GoogleFonts.robotoMono(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Cantidad:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            initialValue: '1',
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _cantidad = int.tryParse(v) ?? 1,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: iconSize,
                        ),
                        label: Text(
                          'Agregar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          textStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          minimumSize: Size(buttonWidth * 0.3, buttonHeight),
                        ),
                        onPressed: _agregarProductoAVenta,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const Divider(),
                Text(
                  'Productos a vender:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                _productosVenta.isEmpty
                    ? Center(
                        child: Text(
                          'No hay productos en la venta',
                          style: GoogleFonts.montserrat(),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _productosVenta.length,
                        itemBuilder: (context, index) {
                          final p = _productosVenta[index];
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple[100],
                                child: Icon(
                                  Icons.shopping_cart,
                                  color: Colors.purple[800],
                                  size: iconSize,
                                ),
                              ),
                              title: Text(
                                p.nombre,
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Cantidad: ${p.cantidad} | Precio: ${p.precioVenta}',
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: iconSize,
                                ),
                                onPressed: () =>
                                    _eliminarProductoDeVenta(index),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 12),
                Text(
                  'Total: $_total',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  label: Text(
                    'Registrar Venta',
                    style: TextStyle(color: Colors.white, fontSize: fontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: Size(buttonWidth * 0.8, buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _productosVenta.isEmpty ? null : _registrarVenta,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
