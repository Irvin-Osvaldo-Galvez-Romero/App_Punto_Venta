class ProductoVendido {
  int productoId;
  String nombre;
  double precioCompra;
  double precioVenta;
  int cantidad;

  ProductoVendido({
    required this.productoId,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.cantidad,
  });

  factory ProductoVendido.fromMap(Map<String, dynamic> map) => ProductoVendido(
    productoId: map['productoId'] as int,
    nombre: map['nombre'] as String,
    precioCompra: map['precioCompra'] as double,
    precioVenta: map['precioVenta'] as double,
    cantidad: map['cantidad'] as int,
  );

  Map<String, dynamic> toMap() => {
    'productoId': productoId,
    'nombre': nombre,
    'precioCompra': precioCompra,
    'precioVenta': precioVenta,
    'cantidad': cantidad,
  };
}

class Venta {
  int? id;
  DateTime fecha;
  List<ProductoVendido> productosVendidos;
  double total;

  Venta({
    this.id,
    required this.fecha,
    required this.productosVendidos,
    required this.total,
  });

  factory Venta.fromMap(Map<String, dynamic> map) => Venta(
    id: map['id'] as int?,
    fecha: DateTime.parse(map['fecha'] as String),
    productosVendidos: (map['productosVendidos'] as List)
        .map((e) => ProductoVendido.fromMap(e as Map<String, dynamic>))
        .toList(),
    total: map['total'] as double,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'productosVendidos': productosVendidos.map((e) => e.toMap()).toList(),
    'total': total,
  };
}
