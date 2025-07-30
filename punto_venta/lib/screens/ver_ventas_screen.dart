import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/db_service.dart';

class VerVentasScreen extends StatefulWidget {
  const VerVentasScreen({super.key});

  @override
  State<VerVentasScreen> createState() => _VerVentasScreenState();
}

class _VerVentasScreenState extends State<VerVentasScreen> {
  List<Venta> _ventasDia = [];
  List<Venta> _ventasMes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _cargando = true);
    final ventas = await DBService.obtenerVentas();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    setState(() {
      _ventasDia = ventas
          .where((v) => v.fecha.isAfter(hoy.subtract(const Duration(days: 1))))
          .toList();
      _ventasMes = ventas
          .where(
            (v) => v.fecha.isAfter(inicioMes.subtract(const Duration(days: 1))),
          )
          .toList();
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = NumberFormat.simpleCurrency(locale: 'es_MX');
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'Ver Ventas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                double buttonWidth = constraints.maxWidth;
                double buttonHeight = 56;
                double iconSize = buttonWidth * 0.07;
                double fontSize = buttonWidth * 0.045;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Text(
                        'Ventas del Día',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._ventasDia.isEmpty
                          ? [
                              Card(
                                elevation: 4,
                                color: theme.cardColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(18),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                    'No hay ventas hoy',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ]
                          : _ventasDia
                                .map(
                                  (venta) => _VentaCard(
                                    venta: venta,
                                    format: format,
                                    color: Colors.green,
                                    cardColor: theme.cardColor,
                                    textColor: theme.colorScheme.onSurface,
                                  ),
                                )
                                .toList(),
                      const SizedBox(height: 24),
                      Text(
                        'Ventas del Mes',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._ventasMes.isEmpty
                          ? [
                              Card(
                                elevation: 4,
                                color: theme.cardColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(18),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                    'No hay ventas este mes',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ]
                          : _ventasMes
                                .map(
                                  (venta) => _VentaCard(
                                    venta: venta,
                                    format: format,
                                    color: Colors.blue,
                                    cardColor: theme.cardColor,
                                    textColor: theme.colorScheme.onSurface,
                                  ),
                                )
                                .toList(),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: iconSize,
                        ),
                        label: Text(
                          'Actualizar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
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
                        onPressed: _cargarVentas,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _VentaCard extends StatelessWidget {
  final Venta venta;
  final NumberFormat format;
  final Color color;
  final Color cardColor;
  final Color textColor;
  const _VentaCard({
    required this.venta,
    required this.format,
    required this.color,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          'Total: ${format.format(venta.total)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha),
          style: TextStyle(color: textColor),
        ),
        children: venta.productosVendidos
            .map(
              (p) => ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.teal),
                title: Text(
                  p.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Cantidad: ${p.cantidad} | Precio: ${format.format(p.precioVenta)}',
                  style: TextStyle(color: textColor),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
