import 'package:cloud_firestore/cloud_firestore.dart';

class Produto {
  String? id;
  String? codigo;
  String? nome;
  String? descricao;
  double? preco;
  String status;
  Timestamp? dataCriacao;
  Timestamp? dataAtualizacao;

  Produto({
    this.id,
    this.codigo,
    this.nome,
    this.descricao,
    this.preco,
    this.status = 'Ativo',
    this.dataCriacao,
    this.dataAtualizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'status': status,
      'dataCriacao': dataCriacao ?? FieldValue.serverTimestamp(),
      'dataAtualizacao': FieldValue.serverTimestamp(),
    };
  }

  factory Produto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return Produto(
      id: doc.id,
      codigo: data['codigo'],
      nome: data['nome'],
      descricao: data['descricao'],
      preco: (data['preco'] as num?)?.toDouble(),
      status: data['status'] ?? 'Ativo',
      dataCriacao: data['dataCriacao'] as Timestamp?,
      dataAtualizacao: data['dataAtualizacao'] as Timestamp?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Produto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
