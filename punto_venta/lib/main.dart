import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'screens/registrar_producto_screen.dart';
import 'screens/ver_productos_screen.dart';
import 'screens/procesar_ventas_screen.dart';
import 'screens/ver_ganancias_screen.dart';
import 'screens/ver_ventas_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart' as xml;
import 'services/db_service.dart';
import 'models/producto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const PuntoVentaApp());
}

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class PuntoVentaApp extends StatelessWidget {
  const PuntoVentaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Punto de Venta',
            theme: FlexThemeData.light(scheme: FlexScheme.mandyRed),
            darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      // Obtener la carpeta Download
      final downloads = Directory('/storage/emulated/0/Download');
      final puntoVentaDir = Directory(p.join(downloads.path, 'punto_Venta'));
      if (!await puntoVentaDir.exists()) {
        await puntoVentaDir.create(recursive: true);
      }
      return puntoVentaDir;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    if (await Permission.storage.isGranted) return true;
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    // Android 11+ requiere MANAGE_EXTERNAL_STORAGE
    if (await Permission.manageExternalStorage.isGranted) return true;
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;
    // Si el usuario lo deniega, abrir la configuración
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso requerido'),
        content: const Text(
          'Para exportar archivos, debes permitir "Acceso a todos los archivos" en la configuración de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Navigator.of(ctx).pop();
            },
            child: const Text('Abrir configuración'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    // Verificar de nuevo después de volver de la configuración
    return await Permission.manageExternalStorage.isGranted;
  }

  Future<void> _exportarProductos(BuildContext context) async {
    try {
      final permiso = await _requestStoragePermission(context);
      if (!permiso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permiso de almacenamiento denegado. No se puede exportar.',
            ),
          ),
        );
        return;
      }
      final productos = await DBService.obtenerProductos();
      final now = DateTime.now();
      final fecha = DateFormat('dd_MM_yyyy').format(now);
      final pdfFileName = 'productos_ventas_${fecha}.pdf';
      final xmlFileName = 'productos_ventas_${fecha}.xml';
      final directory = await _getSaveDirectory();
      final pdfPath = '${directory.path}/$pdfFileName';
      final xmlPath = '${directory.path}/$xmlFileName';

      // PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: [
                'ID',
                'Nombre',
                'Precio Compra',
                'Precio Venta',
                'Código Barras',
                'Stock',
              ],
              data: productos
                  .map(
                    (p) => [
                      p.id?.toString() ?? '',
                      p.nombre,
                      p.precioCompra.toString(),
                      p.precioVenta.toString(),
                      p.codigoBarras,
                      p.cantidadStock.toString(),
                    ],
                  )
                  .toList(),
            );
          },
        ),
      );
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      // XML
      final builder = xml.XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element(
        'productos',
        nest: () {
          for (var p in productos) {
            builder.element(
              'producto',
              nest: () {
                builder.element('id', nest: p.id?.toString() ?? '');
                builder.element('nombre', nest: p.nombre);
                builder.element(
                  'precioCompra',
                  nest: p.precioCompra.toString(),
                );
                builder.element('precioVenta', nest: p.precioVenta.toString());
                builder.element('codigoBarras', nest: p.codigoBarras);
                builder.element(
                  'cantidadStock',
                  nest: p.cantidadStock.toString(),
                );
              },
            );
          }
        },
      );
      final xmlFile = File(xmlPath);
      await xmlFile.writeAsString(
        builder.buildDocument().toXmlString(pretty: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Productos exportados a PDF y XML en: ${directory.path}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar productos: \n' + e.toString()),
        ),
      );
    }
  }

  Future<void> _importarProductos(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final xmlString = await file.readAsString();
      final document = xml.XmlDocument.parse(xmlString);
      final productosXml = document.findAllElements('producto');
      int countAgregados = 0;
      int countActualizados = 0;
      int countSinCambios = 0;
      for (var pXml in productosXml) {
        final nombre = pXml.getElement('nombre')?.text ?? '';
        final precioCompra =
            double.tryParse(pXml.getElement('precioCompra')?.text ?? '') ?? 0.0;
        final precioVenta =
            double.tryParse(pXml.getElement('precioVenta')?.text ?? '') ?? 0.0;
        final codigoBarras = pXml.getElement('codigoBarras')?.text ?? '';
        final cantidadStock =
            int.tryParse(pXml.getElement('cantidadStock')?.text ?? '') ?? 0;
        if (nombre.isNotEmpty && codigoBarras.isNotEmpty) {
          final producto = Producto(
            nombre: nombre,
            precioCompra: precioCompra,
            precioVenta: precioVenta,
            codigoBarras: codigoBarras,
            cantidadStock: cantidadStock,
          );
          final existente = await DBService.buscarProductoPorCodigo(
            codigoBarras,
          );
          if (existente != null) {
            // Comparar todos los campos
            if (existente.nombre == nombre &&
                existente.precioCompra == precioCompra &&
                existente.precioVenta == precioVenta &&
                existente.cantidadStock == cantidadStock) {
              countSinCambios++;
            } else {
              final actualizado = Producto(
                id: existente.id,
                nombre: nombre,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                codigoBarras: codigoBarras,
                cantidadStock: cantidadStock,
              );
              await DBService.actualizarProducto(actualizado);
              countActualizados++;
            }
          } else {
            await DBService.agregarProducto(producto);
            countAgregados++;
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Importados: $countAgregados, Actualizados: $countActualizados, Sin cambios: $countSinCambios productos desde XML.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar productos: \n' + e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final buttonData = [
      {
        'color': Colors.green,
        'icon': Icons.add_box,
        'label': 'Registrar Productos',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegistrarProductoScreen()),
          );
        },
      },
      {
        'color': Colors.blue,
        'icon': Icons.list_alt,
        'label': 'Ver Productos',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerProductosScreen()),
          );
        },
      },
      {
        'color': Colors.orange,
        'icon': Icons.qr_code_scanner,
        'label': 'Escanear Código de Barras',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerProductosScreen()),
          );
        },
      },
      {
        'color': Colors.purple,
        'icon': Icons.point_of_sale,
        'label': 'Procesar Venta',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProcesarVentasScreen()),
          );
        },
      },
      {
        'color': Colors.teal,
        'icon': Icons.attach_money,
        'label': 'Ver Ganancias',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerGananciasScreen()),
          );
        },
      },
      {
        'color': Colors.red,
        'icon': Icons.bar_chart,
        'label': 'Ver Ventas',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VerVentasScreen()),
          );
        },
      },
      {
        'color': Colors.indigo,
        'icon': Icons.file_download,
        'label': 'Exportar productos',
        'onTap': () => _exportarProductos(context),
      },
      {
        'color': Colors.brown,
        'icon': Icons.file_upload,
        'label': 'Importar productos',
        'onTap': () => _importarProductos(context),
      },
    ];
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Menú Principal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.yellow[300] : Colors.black,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: isDark ? 'Tema claro' : 'Tema oscuro',
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth < 500 ? 2 : 3;
          double gridSpacing = 24;
          double buttonWidth =
              (constraints.maxWidth - (gridSpacing * (crossAxisCount + 1))) /
              crossAxisCount;
          double buttonHeight = buttonWidth * 0.9;
          double iconSize = buttonWidth * 0.22;
          double fontSize = buttonWidth * 0.10;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GridView.builder(
              itemCount: buttonData.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: gridSpacing,
                crossAxisSpacing: gridSpacing,
                childAspectRatio: buttonWidth / buttonHeight,
              ),
              itemBuilder: (context, index) {
                final data = buttonData[index];
                return Material(
                  color: data['color'] as Color,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: data['onTap'] as VoidCallback,
                    child: SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: Padding(
                        padding: EdgeInsets.all(buttonWidth * 0.08),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              data['icon'] as IconData,
                              size: iconSize,
                              color: Colors.white,
                            ),
                            SizedBox(height: buttonHeight * 0.08),
                            Text(
                              data['label'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize,
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
          );
        },
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DashboardButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 60),
        textStyle: const TextStyle(fontSize: 18),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 28),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
