import 'dart:convert';
import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:maicosoft/models/cliente.dart';
import 'package:maicosoft/services/firebase_services.dart';

class EditClienteView extends StatefulWidget {
  final Cliente cliente;
  final VoidCallback onClose;

  const EditClienteView({
    super.key,
    required this.cliente,
    required this.onClose,
  });

  @override
  State<EditClienteView> createState() => _EditClienteViewState();
}

class _EditClienteViewState extends State<EditClienteView> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();
  bool _isSaving = false;
  bool _isFetchingCep = false;

  String? _selectedStatus;
  String? _tipoPessoaSelecionado;
  String? _fiscalJuridicoSelecionado;

  late TextEditingController _nomeContatoController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _cnpjCpfController;
  late TextEditingController _nomeFantasiaController;
  late TextEditingController _lojaController;
  late TextEditingController _homePageController;
  late TextEditingController _telefoneEmpresaController;
  late TextEditingController _dataAberturaNascimentoController;
  late TextEditingController _enderecoController;
  late TextEditingController _bairroController;
  late TextEditingController _cepController;
  late TextEditingController _municipioController;
  late TextEditingController _codigoMunicipioController;
  late TextEditingController _estadoController;
  late TextEditingController _paisController;
  late TextEditingController _numController;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _dateFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupInitialDropdownValues();
    _cepController.addListener(_onCepChanged);
  }

  void _initializeControllers() {
    String rua = '';
    String numero = '';

    if (widget.cliente.endereco != null &&
        widget.cliente.endereco!.contains(',')) {
      final parts = widget.cliente.endereco!.split(',');
      rua = parts[0].trim();
      if (parts.length > 1) {
        numero = parts[1].trim();
      }
    } else {
      rua = widget.cliente.endereco ?? '';
    }

    String dataFormatada = '';
    if (widget.cliente.dataAberturaNascimento != null) {
      final data = widget.cliente.dataAberturaNascimento!.toDate();
      dataFormatada = DateFormat('dd/MM/yyyy').format(data);
    }

    _nomeContatoController = TextEditingController(
      text: widget.cliente.nomeContato ?? '',
    );
    _emailController = TextEditingController(
      text: widget.cliente.emailContato ?? '',
    );
    _telefoneController = TextEditingController(
      text: widget.cliente.telefoneContato ?? '',
    );
    _cnpjCpfController = TextEditingController(
      text: widget.cliente.cnpjCpf ?? '',
    );
    _nomeFantasiaController = TextEditingController(
      text: widget.cliente.nomeFantasia ?? '',
    );
    _lojaController = TextEditingController(text: widget.cliente.loja ?? '');
    _homePageController = TextEditingController(
      text: widget.cliente.homePage ?? '',
    );
    _telefoneEmpresaController = TextEditingController(
      text: widget.cliente.telefoneEmpresa ?? '',
    );
    _dataAberturaNascimentoController = TextEditingController(
      text: dataFormatada,
    );
    _enderecoController = TextEditingController(text: rua);
    _numController = TextEditingController(text: numero);

    _bairroController = TextEditingController(
      text: widget.cliente.bairro ?? '',
    );
    _cepController = TextEditingController(text: widget.cliente.cep ?? '');
    _municipioController = TextEditingController(
      text: widget.cliente.municipio ?? '',
    );
    _codigoMunicipioController = TextEditingController(
      text: widget.cliente.codigoMunicipio ?? '',
    );
    _estadoController = TextEditingController(
      text: widget.cliente.estado ?? '',
    );
    _paisController = TextEditingController(text: widget.cliente.pais ?? '');
  }

  void _setupInitialDropdownValues() {
    final statusOptions = ['Incompleto', 'Ativo', 'Inativo'];
    final tipoPessoaOptions = ['Pessoa Física', 'Pessoa Jurídica'];
    final fiscalJuridicoOptions = [
      'MEI',
      'LTDA',
      'EIRELI',
      'SA',
      'Simples Nacional',
      'Outro',
    ];

    if (statusOptions.contains(widget.cliente.statusCliente)) {
      _selectedStatus = widget.cliente.statusCliente;
    } else {
      _selectedStatus = null;
    }

    if (tipoPessoaOptions.contains(widget.cliente.tipo)) {
      _tipoPessoaSelecionado = widget.cliente.tipo;
    } else {
      _tipoPessoaSelecionado = null;
    }

    if (fiscalJuridicoOptions.contains(widget.cliente.fiscalJuridico)) {
      _fiscalJuridicoSelecionado = widget.cliente.fiscalJuridico;
    } else {
      _fiscalJuridicoSelecionado = null;
    }
  }

  void _onCepChanged() {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length == 8) {
      _buscarCep(cep);
    }
  }

  Future<void> _buscarCep(String cep) async {
    setState(() => _isFetchingCep = true);
    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] != true) {
          setState(() {
            _enderecoController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _municipioController.text = data['localidade'] ?? '';
            _codigoMunicipioController.text = data['ibge'] ?? '';
            _estadoController.text = data['uf'] ?? '';
            _paisController.text = 'Brasil';
          });
        } else {
          _showErrorSnackBar('CEP não encontrado.');
        }
      } else {
        _showErrorSnackBar('Erro ao buscar CEP.');
      }
    } catch (e) {
      _showErrorSnackBar('Erro de conexão ao buscar CEP.');
    } finally {
      if (mounted) {
        setState(() => _isFetchingCep = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    dynamic dataAberturaNascimentoConvertida;
    final dataTexto = _dataAberturaNascimentoController.text.trim();
    if (dataTexto.isNotEmpty) {
      try {
        final dataFormatada = DateFormat('dd/MM/yyyy').parse(dataTexto);
        dataAberturaNascimentoConvertida = dataFormatada;
      } catch (e) {
        _showErrorSnackBar('Data de Abertura/Nascimento inválida.');
        setState(() => _isSaving = false);
        return;
      }
    } else {
      dataAberturaNascimentoConvertida = null;
    }

    try {
      final updatedData = {
        'nomeContato': _nomeContatoController.text.trim(),
        'emailContato': _emailController.text.trim(),
        'telefoneContato': _telefoneController.text,
        'cnpjCpf': _cnpjCpfController.text,
        'statusCliente': _selectedStatus,
        'nomeFantasia': _nomeFantasiaController.text.trim(),
        'tipo': _tipoPessoaSelecionado,
        'fiscalJuridico': _fiscalJuridicoSelecionado ?? '',
        'loja': _lojaController.text.trim(),
        'homePage': _homePageController.text.trim(),
        'telefoneEmpresa': _telefoneEmpresaController.text,
        'dataAberturaNascimento': dataAberturaNascimentoConvertida,
        'endereco':
            '${_enderecoController.text.trim()}, ${_numController.text.trim()}',
        'bairro': _bairroController.text.trim(),
        'cep': _cepController.text,
        'municipio': _municipioController.text.trim(),
        'codigoMunicipio': _codigoMunicipioController.text.trim(),
        'estado': _estadoController.text.trim(),
        'pais': _paisController.text.trim(),
      };
      await _firebaseServices.atualizarCliente(widget.cliente.id!, updatedData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza de que deseja excluir? Esta ação não pode ser desfeita.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _firebaseServices.excluirCliente(widget.cliente.id!);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cliente excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onClose();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir cliente: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cepController.removeListener(_onCepChanged);
    _nomeContatoController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cnpjCpfController.dispose();
    _nomeFantasiaController.dispose();
    _lojaController.dispose();
    _homePageController.dispose();
    _telefoneEmpresaController.dispose();
    _dataAberturaNascimentoController.dispose();
    _enderecoController.dispose();
    _bairroController.dispose();
    _cepController.dispose();
    _municipioController.dispose();
    _codigoMunicipioController.dispose();
    _estadoController.dispose();
    _paisController.dispose();
    _numController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;
        return isWide ? _buildWideLayout() : _buildNarrowLayout();
      },
    );
  }

  Widget _buildWideLayout() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 45),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Editar Cliente - Cód: ${widget.cliente.codigo}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => _showDeleteConfirmationDialog(context),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Excluir Cliente',
                    color: Colors.red.shade700,
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_outlined),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildSectionTitle('Status e Contato Principal'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildStatusDropdown()),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _textForm(
                          _nomeContatoController,
                          'Nome de Contato *',
                          'Nome de Contato',
                          validator:
                              (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _textForm(
                          _emailController,
                          'E-mail *',
                          'exemplo@empresa.com',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Campo obrigatório';
                            }
                            final emailRegex = RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Por favor, insira um e-mail válido.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _textForm(
                          _telefoneController,
                          'Telefone de Contato',
                          'Ex: (15) 12345-6789',
                          formatters: [_phoneFormatter],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildSectionTitle('Dados da Empresa'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTipoPessoaDropdown()),
                      const SizedBox(width: 24),
                      if (_tipoPessoaSelecionado == 'Pessoa Física')
                        Expanded(
                          child: _textForm(
                            _cnpjCpfController,
                            'CPF',
                            '000.000.000-00',
                            formatters: [_cpfFormatter],
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  !CPFValidator.isValid(value)) {
                                return 'CPF inválido';
                              }
                              return null;
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: _textForm(
                            _cnpjCpfController,
                            'CNPJ',
                            '00.000.000/0000-00',
                            formatters: [_cnpjFormatter],
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  !CNPJValidator.isValid(value)) {
                                return 'CNPJ inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _textForm(
                          _nomeFantasiaController,
                          _tipoPessoaSelecionado == 'Pessoa Física'
                              ? 'Nome Completo *'
                              : 'Nome Fantasia *',
                          'Nome',
                          validator:
                              (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _textForm(
                          _dataAberturaNascimentoController,
                          _tipoPessoaSelecionado == 'Pessoa Física'
                              ? 'Data de Nascimento'
                              : 'Data de Abertura',
                          'dd/mm/aaaa',
                          formatters: [_dateFormatter],
                        ),
                      ),
                    ],
                  ),

                  if (_tipoPessoaSelecionado == 'Pessoa Jurídica') ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildFiscalJuridicoDropdown()),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: 150,
                          child: _textForm(
                            _lojaController,
                            'Loja *',
                            '001',
                            validator:
                                (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _textForm(
                          _homePageController,
                          'Website',
                          'www.exemplo.com.br',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _textForm(
                          _telefoneEmpresaController,
                          'Telefone da Empresa',
                          'Ex: (15) 12345-6789',
                          formatters: [_phoneFormatter],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 32),

                  _buildSectionTitle('Endereço'),
                  _textForm(
                    _cepController,
                    'CEP',
                    '12345-678',
                    formatters: [_cepFormatter],
                    suffixIcon:
                        _isFetchingCep
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : const Icon(Icons.search),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _textForm(
                          _enderecoController,
                          'Endereço *',
                          'Rua Exemplo',
                          validator:
                              (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 120,
                        child: _textForm(
                          _numController,
                          'Número *',
                          '399',
                          validator:
                              (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _textForm(_bairroController, 'Bairro', 'Bairro'),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _textForm(
                          _municipioController,
                          'Município / Cidade *',
                          'Nome da Cidade',
                          validator:
                              (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 200,
                        child: _textForm(
                          _codigoMunicipioController,
                          'Cód. do Município',
                          '15',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: _textForm(
                          _estadoController,
                          'Estado (UF) *',
                          'SP',
                          validator:
                              (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _textForm(_paisController, 'País', 'Brasil'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 45),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: widget.onClose,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 25,
                          ),
                          side: const BorderSide(color: Colors.black54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _salvarAlteracoes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFc62828),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 25,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                                : const Text(
                                  'Salvar',
                                  style: TextStyle(color: Colors.white),
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildSectionTitle('Status e Contato Principal'),
                  _buildStatusDropdown(),
                  const SizedBox(height: 24),
                  _textForm(
                    _nomeContatoController,
                    'Nome de Contato *',
                    'Nome de Contato',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _emailController,
                    'E-mail *',
                    'exemplo@empresa.com',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final emailRegex = RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Por favor, insira um e-mail válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _telefoneController,
                    'Telefone de Contato',
                    'Ex: (15) 12345-6789',
                    formatters: [_phoneFormatter],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Dados da Empresa'),
                  _buildTipoPessoaDropdown(),
                  const SizedBox(height: 24),
                  _buildCnpjCpfField(),
                  const SizedBox(height: 24),
                  _textForm(
                    _nomeFantasiaController,
                    _tipoPessoaSelecionado == 'Pessoa Física'
                        ? 'Nome Completo *'
                        : 'Nome Fantasia *',
                    'Nome',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _dataAberturaNascimentoController,
                    _tipoPessoaSelecionado == 'Pessoa Física'
                        ? 'Data de Nascimento'
                        : 'Data de Abertura',
                    'dd/mm/aaaa',
                    formatters: [_dateFormatter],
                  ),

                  if (_tipoPessoaSelecionado == 'Pessoa Jurídica') ...[
                    const SizedBox(height: 24),
                    _buildFiscalJuridicoDropdown(),
                    const SizedBox(height: 24),
                    _textForm(
                      _lojaController,
                      'Loja *',
                      '001',
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _textForm(
                    _homePageController,
                    'Website',
                    'www.exemplo.com.br',
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _telefoneEmpresaController,
                    'Telefone da Empresa',
                    'Ex: (15) 12345-6789',
                    formatters: [_phoneFormatter],
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Endereço'),
                  _buildCepField(),
                  const SizedBox(height: 24),
                  _textForm(
                    _enderecoController,
                    'Endereço *',
                    'Rua Exemplo',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _numController,
                    'Número *',
                    '399',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  _textForm(_bairroController, 'Bairro', 'Bairro'),
                  const SizedBox(height: 24),
                  _textForm(
                    _municipioController,
                    'Município / Cidade *',
                    'Nome da Cidade',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _codigoMunicipioController,
                    'Cód. do Município',
                    '15',
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _estadoController,
                    'Estado (UF) *',
                    'SP',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  _textForm(_paisController, 'País', 'Brasil'),

                  const SizedBox(height: 45),
                  _buildActionButtons(isWide: false),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Editar Cliente - Cód: ${widget.cliente.codigo}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => _showDeleteConfirmationDialog(context),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir Cliente',
              color: Colors.red.shade700,
            ),
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCnpjCpfField() {
    if (_tipoPessoaSelecionado == 'Pessoa Física') {
      return _textForm(
        _cnpjCpfController,
        'CPF',
        '000.000.000-00',
        formatters: [_cpfFormatter],
        validator: (value) {
          if (value != null &&
              value.isNotEmpty &&
              !CPFValidator.isValid(value)) {
            return 'CPF inválido';
          }
          return null;
        },
      );
    } else {
      return _textForm(
        _cnpjCpfController,
        'CNPJ',
        '00.000.000/0000-00',
        formatters: [_cnpjFormatter],
        validator: (value) {
          if (value != null &&
              value.isNotEmpty &&
              !CNPJValidator.isValid(value)) {
            return 'CNPJ inválido';
          }
          return null;
        },
      );
    }
  }

  Widget _buildCepField() {
    return _textForm(
      _cepController,
      'CEP',
      '12345-678',
      formatters: [_cepFormatter],
      suffixIcon:
          _isFetchingCep
              ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : const Icon(Icons.search),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD00236),
        ),
      ),
    );
  }

  Widget _buildActionButtons({required bool isWide}) {
    final cancelButton = OutlinedButton(
      onPressed: widget.onClose,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 100 : 20,
          vertical: 20,
        ),
        side: const BorderSide(color: Colors.black54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
    );

    final saveButton = ElevatedButton(
      onPressed: _isSaving ? null : _salvarAlteracoes,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFc62828),
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 100 : 20,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child:
          _isSaving
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              )
              : const Text('Salvar', style: TextStyle(color: Colors.white)),
    );

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [cancelButton, const SizedBox(width: 16), saveButton],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [saveButton, const SizedBox(height: 12), cancelButton],
      );
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items:
              items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                );
              }).toList(),
          onChanged: onChanged,
          decoration: _getInputDecoration(hint: hint),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return _buildDropdown<String>(
      label: 'Status *',
      hint: 'Selecione o Status',
      value: _selectedStatus,
      items: ['Incompleto', 'Ativo', 'Inativo'],
      onChanged: (newValue) => setState(() => _selectedStatus = newValue),
      validator: (v) => v == null || v.isEmpty ? 'Selecione um status.' : null,
    );
  }

  Widget _buildTipoPessoaDropdown() {
    return _buildDropdown<String>(
      label: 'Tipo de Pessoa *',
      hint: 'Selecione o Tipo',
      value: _tipoPessoaSelecionado,
      items: ['Pessoa Física', 'Pessoa Jurídica'],
      onChanged: (newValue) {
        setState(() {
          _tipoPessoaSelecionado = newValue;
          _cnpjCpfController.clear();
          _fiscalJuridicoSelecionado = null;
        });
      },
      validator: (v) => v == null || v.isEmpty ? 'Selecione um tipo.' : null,
    );
  }

  Widget _buildFiscalJuridicoDropdown() {
    return _buildDropdown<String>(
      label: 'Regime Fiscal/Jurídico',
      hint: 'Selecione o Regime',
      value: _fiscalJuridicoSelecionado,
      items: ['MEI', 'LTDA', 'EIRELI', 'SA', 'Simples Nacional', 'Outro'],
      onChanged:
          (newValue) => setState(() => _fiscalJuridicoSelecionado = newValue),
    );
  }

  Widget _textForm(
    TextEditingController controller,
    String label,
    String hint, {
    FormFieldValidator<String>? validator,
    List<MaskTextInputFormatter>? formatters,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          inputFormatters: formatters,
          decoration: _getInputDecoration(hint: hint, suffixIcon: suffixIcon),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.red.shade600, width: 2.0),
      ),
    );
  }
}
