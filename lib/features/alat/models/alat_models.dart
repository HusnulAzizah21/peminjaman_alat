class AlatModel {
  final int id;
  final String namaAlat;
  final int stokTotal;
  final String? deskripsi;
  final String? namaKategori;

  AlatModel({
    required this.id,
    required this.namaAlat,
    required this.stokTotal,
    this.deskripsi,
    this.namaKategori,
  });

  factory AlatModel.fromJson(Map<String, dynamic> json) {
    return AlatModel(
      id: json['id'],
      namaAlat: json['nama_alat'],
      stokTotal: json['stok_total'],
      deskripsi: json['deskripsi'],
      namaKategori: json['kategori']?['nama_kategori'],
    );
  }
}