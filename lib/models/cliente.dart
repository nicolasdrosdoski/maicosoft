import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Cliente {
  String? id;

  String? cnpjCpf;
  String? nomeContato;
  String? emailContato;
  String? telefoneContato;

  String? nomeFantasia;
  String? codigo;
  String? tipo;
  String? fiscalJuridico;
  String? loja;
  String? homePage;
  String? telefoneEmpresa;
  Timestamp? dataAberturaNascimento;
  String statusCliente;

  String? endereco;
  String? bairro;
  String? cep;
  String? municipio;
  String? codigoMunicipio;
  String? estado;
  String? pais;
  String? ddd;

  Timestamp? dataCriacao;
  Timestamp? dataAtualizacao;

  Cliente({
    this.id,
    this.dataCriacao,
    this.dataAtualizacao,
    //* Vendedor
    this.cnpjCpf,
    this.nomeContato,
    this.emailContato,
    this.telefoneContato,
    //* Funcionário
    this.nomeFantasia,
    this.codigo,
    this.tipo,
    this.fiscalJuridico,
    this.loja,
    this.homePage,
    this.telefoneEmpresa,
    this.dataAberturaNascimento,
    this.endereco,
    this.bairro,
    this.cep,
    this.municipio,
    this.codigoMunicipio,
    this.estado,
    this.pais,
    this.ddd,
    this.statusCliente = "Incompleto",
  });

  Map<String, dynamic> toMap() {
    return {
      //* Vendedor
      'cnpjCpf': cnpjCpf,
      'nomeContato': nomeContato,
      'emailContato': emailContato,
      'telefoneContato': telefoneContato,
      //* Funcionário
      'nomeFantasia': nomeFantasia,
      'codigo': codigo,
      'tipo': tipo,
      'fiscalJuridico': fiscalJuridico,
      'loja': loja,
      'homePage': homePage,
      'telefoneEmpresa': telefoneEmpresa,
      'dataAberturaNascimento': dataAberturaNascimento,
      'endereco': endereco,
      'bairro': bairro,
      'cep': cep,
      'municipio': municipio,
      'codigoMunicipio': codigoMunicipio,
      'estado': estado,
      'pais': pais,
      'ddd': ddd,
      'statusCliente': statusCliente,
    };
  }

  factory Cliente.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    Timestamp? normalizedDate;
    final dateValue = data['dataAberturaNascimento'];
    if (dateValue is Timestamp) {
      normalizedDate = dateValue;
    } else if (dateValue is String && dateValue.isNotEmpty) {
      try {
        final parsedDate = DateFormat('dd/MM/yyyy').parse(dateValue);
        normalizedDate = Timestamp.fromDate(parsedDate);
      } catch (e) {
        normalizedDate = null;
      }
    }

    return Cliente(
      id: doc.id,
      dataCriacao: data['dataCriacao'] as Timestamp?,
      dataAtualizacao: data['dataAtualizacao'] as Timestamp?,

      dataAberturaNascimento: normalizedDate,

      //* Vendedor
      cnpjCpf: data['cnpjCpf'],
      nomeContato: data['nomeContato'],
      emailContato: data['emailContato'],
      telefoneContato: data['telefoneContato'],
      //* Funcionário
      nomeFantasia: data['nomeFantasia'],
      codigo: data['codigo'],
      tipo: data['tipo'],
      fiscalJuridico: data['fiscalJuridico'],
      loja: data['loja'],
      homePage: data['homePage'],
      telefoneEmpresa: data['telefoneEmpresa'],
      endereco: data['endereco'],
      bairro: data['bairro'],
      cep: data['cep'],
      municipio: data['municipio'],
      codigoMunicipio: data['codigoMunicipio'],
      estado: data['estado'],
      pais: data['pais'],
      ddd: data['ddd'],
      statusCliente: data['statusCliente'] ?? 'Incompleto',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cliente && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
