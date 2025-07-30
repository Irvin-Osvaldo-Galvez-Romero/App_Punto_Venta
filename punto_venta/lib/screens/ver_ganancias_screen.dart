import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/venta.dart';
import '../services/db_service.dart';

class VerGananciasScreen extends StatefulWidget {
  const VerGananciasScreen({super.key});

  @override
  State<VerGananciasScreen> createState() => _VerGananciasScreenState();
}

class _VerGananciasScreenState extends State<VerGananciasScreen> {
  double _gananciaDia = 0.0;
  double _gananciaSemana = 0.0;
  double _gananciaMes = 0.0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _calcularGanancias();
  }

  Future<void> _calcularGanancias() async {
    setState(() => _cargando = true);
    final ventas = await DBService.obtenerVentas();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    double dia = 0.0, semana = 0.0, mes = 0.0;
    for (final venta in ventas) {
      if (venta.fecha.isAfter(hoy.subtract(const Duration(days: 1)))) {
        dia += _gananciaVenta(venta);
      }
      if (venta.fecha.isAfter(inicioSemana.subtract(const Duration(days: 1)))) {
        semana += _gananciaVenta(venta);
      }
      if (venta.fecha.isAfter(inicioMes.subtract(const Duration(days: 1)))) {
        mes += _gananciaVenta(venta);
      }
    }
    setState(() {
      _gananciaDia = dia;
      _gananciaSemana = semana;
      _gananciaMes = mes;
      _cargando = false;
    });
  }

  double _gananciaVenta(Venta venta) {
    double ganancia = 0.0;
    for (final p in venta.productosVendidos) {
      ganancia += (p.precioVenta - p.precioCompra) * p.cantidad;
    }
    return ganancia;
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
          'Ver Ganancias',
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
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    children: [
                      _GananciaCard(
                        title: 'Ganancia del Día',
                        value: format.format(_gananciaDia),
                        color: Colors.green,
                        cardColor: theme.cardColor,
                        textColor: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(height: 20),
                      _GananciaCard(
                        title: 'Ganancia de la Semana',
                        value: format.format(_gananciaSemana),
                        color: Colors.blue,
                        cardColor: theme.cardColor,
                        textColor: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(height: 20),
                      _GananciaCard(
                        title: 'Ganancia del Mes',
                        value: format.format(_gananciaMes),
                        color: Colors.orange,
                        cardColor: theme.cardColor,
                        textColor: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(height: 32),
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
                          backgroundColor: Colors.teal,
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
                        onPressed: _calcularGanancias,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _GananciaCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color cardColor;
  final Color textColor;
  const _GananciaCard({
    required this.title,
    required this.value,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
