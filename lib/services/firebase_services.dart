import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:maicosoft/models/cliente.dart';
import 'package:maicosoft/models/pedido.dart';
import 'package:maicosoft/models/produto.dart';

class FirebaseServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> salvarNovoCliente(Cliente novoCliente) async {
    try {
      Map<String, dynamic> clienteData = novoCliente.toMap();
      clienteData['dataCriacao'] = FieldValue.serverTimestamp();
      clienteData['dataAtualizacao'] = FieldValue.serverTimestamp();

      await _db.collection('clientes').add(clienteData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> atualizarCliente(
    String clienteId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['dataAtualizacao'] = FieldValue.serverTimestamp();
      await _db.collection('clientes').doc(clienteId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Cliente>> getOportunidades() {
    Query collectionRef = _db.collection('clientes');

    collectionRef = collectionRef
        .where('statusCliente', isEqualTo: 'Incompleto')
        .orderBy('dataCriacao', descending: true);

    return collectionRef.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Cliente.fromFirestore(doc);
      }).toList();
    });
  }

  Stream<List<Cliente>> getClientes({
    String? searchQuery,
    String status = 'Todos',
    String tipo = 'Todos',
    String? cidade,
  }) {
    Query query = _db.collection('clientes');

    query = query.where('statusCliente', whereIn: ['Ativo', 'Inativo']);

    if (status != 'Todos') {
      query = query.where('statusCliente', isEqualTo: status);
    }
    if (tipo != 'Todos') {
      query = query.where('tipo', isEqualTo: tipo);
    }
    if (cidade != null && cidade.isNotEmpty) {
      query = query.where('municipio', isEqualTo: cidade);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('nomeFantasia', isGreaterThanOrEqualTo: searchQuery)
          .where('nomeFantasia', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }

    query = query.orderBy('nomeFantasia', descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }

  Future<void> excluirCliente(String clienteId) async {
    try {
      await _db.collection('clientes').doc(clienteId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Produto>> getProdutos({String? searchQuery, String? status}) {
    Query query = _db.collection('produtos');

    if (status != null && status != 'Todos') {
      query = query.where('status', isEqualTo: status);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('nome', isGreaterThanOrEqualTo: searchQuery)
          .where('nome', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Produto.fromFirestore(doc)).toList();
    });
  }

  Future<void> salvarNovoProduto(Produto produto) async {
    try {
      await _db.collection('produtos').add(produto.toMap());
    } catch (e) {
      debugPrint('Erro ao salvar novo produto: $e');
      rethrow;
    }
  }

  Future<void> atualizarProduto(String id, Map<String, dynamic> data) async {
    try {
      data['dataAtualizacao'] = FieldValue.serverTimestamp();
      await _db.collection('produtos').doc(id).update(data);
    } catch (e) {
      debugPrint('Erro ao atualizar produto: $e');
      rethrow;
    }
  }

  Future<void> excluirProduto(String id) async {
    try {
      await _db.collection('produtos').doc(id).delete();
    } catch (e) {
      debugPrint('Erro ao excluir produto: $e');
      rethrow;
    }
  }

  Stream<List<Pedido>> getPedidos({
    String? searchQuery,
    String status = 'Todos',
  }) {
    Query query = _db.collection('pedidos');

    if (status != 'Todos') {
      query = query.where('status', isEqualTo: status);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('clienteNome', isGreaterThanOrEqualTo: searchQuery)
          .where('clienteNome', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }

    query = query.orderBy('dataCriacao', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Pedido.fromFirestore(doc)).toList();
    });
  }

  Future<void> salvarNovoPedido(Pedido pedido) async {
    try {
      await _db.collection('pedidos').add(pedido.toMap());
    } catch (e) {
      debugPrint('Erro ao salvar novo pedido: $e');
      rethrow;
    }
  }

  Future<void> atualizarPedido(String id, Map<String, dynamic> data) async {
    try {
      data['dataAtualizacao'] = FieldValue.serverTimestamp();
      await _db.collection('pedidos').doc(id).update(data);
    } catch (e) {
      debugPrint('Erro ao atualizar pedido: $e');
      rethrow;
    }
  }

  Future<void> excluirPedido(String id) async {
    try {
      await _db.collection('pedidos').doc(id).delete();
    } catch (e) {
      debugPrint('Erro ao excluir pedido: $e');
      rethrow;
    }
  }

  Stream<List<Cliente>> getClientesAtivos() {
    Query query = _db
        .collection('clientes')
        .where('statusCliente', isEqualTo: 'Ativo')
        .orderBy('nomeFantasia', descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Cliente.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Produto>> getProdutosAtivos() {
    Query query = _db
        .collection('produtos')
        .where('status', isEqualTo: 'Ativo')
        .orderBy('nome', descending: false);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Produto.fromFirestore(doc)).toList();
    });
  }
}
