import 'package:cloud_firestore/cloud_firestore.dart';

class PedidoItem {
  final String produtoId;
  final String produtoNome;
  final int quantidade;
  final double precoUnitario;

  PedidoItem({
    required this.produtoId,
    required this.produtoNome,
    required this.quantidade,
    required this.precoUnitario,
  });

  Map<String, dynamic> toMap() {
    return {
      'produtoId': produtoId,
      'produtoNome': produtoNome,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
    };
  }

  factory PedidoItem.fromMap(Map<String, dynamic> map) {
    return PedidoItem(
      produtoId: map['produtoId'],
      produtoNome: map['produtoNome'],
      quantidade: map['quantidade'],
      precoUnitario: (map['precoUnitario'] as num).toDouble(),
    );
  }
}

class Pedido {
  String? id;
  String? codigo;
  String clienteId;
  String clienteNome;
  List<PedidoItem> itens;
  double valorTotal;
  String status;
  String? observacoes;
  Timestamp? dataCriacao;
  Timestamp? dataAtualizacao;

  Pedido({
    this.id,
    this.codigo,
    required this.clienteId,
    required this.clienteNome,
    required this.itens,
    required this.valorTotal,
    this.status = 'Pendente',
    this.observacoes,
    this.dataCriacao,
    this.dataAtualizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'itens': itens.map((item) => item.toMap()).toList(),
      'valorTotal': valorTotal,
      'status': status,
      'observacoes': observacoes,
      'dataCriacao': dataCriacao ?? FieldValue.serverTimestamp(),
      'dataAtualizacao': FieldValue.serverTimestamp(),
    };
  }

  factory Pedido.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return Pedido(
      id: doc.id,
      codigo: data['codigo'],
      clienteId: data['clienteId'],
      clienteNome: data['clienteNome'],
      itens:
          (data['itens'] as List<dynamic>? ?? [])
              .map(
                (itemData) =>
                    PedidoItem.fromMap(itemData as Map<String, dynamic>),
              )
              .toList(),
      valorTotal: (data['valorTotal'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Pendente',
      observacoes: data['observacoes'],
      dataCriacao: data['dataCriacao'] as Timestamp?,
      dataAtualizacao: data['dataAtualizacao'] as Timestamp?,
    );
  }
}
