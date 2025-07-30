class Producto {
  int? id;
  String nombre;
  double precioCompra;
  double precioVenta;
  String codigoBarras;
  int cantidadStock;

  Producto({
    this.id,
    required this.nombre,
    required this.precioCompra,
    required this.precioVenta,
    required this.codigoBarras,
    required this.cantidadStock,
  });

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
    id: map['id'] as int?,
    nombre: map['nombre'] as String,
    precioCompra: map['precioCompra'] as double,
    precioVenta: map['precioVenta'] as double,
    codigoBarras: map['codigoBarras'] as String,
    cantidadStock: map['cantidadStock'] as int,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'precioCompra': precioCompra,
    'precioVenta': precioVenta,
    'codigoBarras': codigoBarras,
    'cantidadStock': cantidadStock,
  };
}
