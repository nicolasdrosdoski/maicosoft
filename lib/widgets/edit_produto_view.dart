import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maicosoft/models/produto.dart';
import 'package:maicosoft/services/firebase_services.dart';

class EditProdutoView extends StatefulWidget {
  final Produto produto;
  final VoidCallback onClose;

  const EditProdutoView({
    super.key,
    required this.produto,
    required this.onClose,
  });

  @override
  State<EditProdutoView> createState() => _EditProdutoViewState();
}

class _EditProdutoViewState extends State<EditProdutoView> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();
  bool _isSaving = false;

  String? _selectedStatus;

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupInitialDropdownValues();
  }

  void _initializeControllers() {
    _nomeController = TextEditingController(text: widget.produto.nome ?? '');
    _descricaoController = TextEditingController(
      text: widget.produto.descricao ?? '',
    );
    _precoController = TextEditingController(
      text:
          widget.produto.preco != null
              ? NumberFormat.currency(
                locale: 'pt_BR',
                symbol: '',
              ).format(widget.produto.preco)
              : '',
    );
  }

  void _setupInitialDropdownValues() {
    _selectedStatus = widget.produto.status;
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

    try {
      final updatedData = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'preco': double.tryParse(
          _precoController.text.replaceAll('.', '').replaceAll(',', '.'),
        ),
        'status': _selectedStatus,
      };

      await _firebaseServices.atualizarProduto(widget.produto.id!, updatedData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onClose();
    } catch (e) {
      _showErrorSnackBar('Erro ao atualizar produto: $e');
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
          content: const Text(
            'Tem certeza de que deseja excluir? Esta ação não pode ser desfeita.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _firebaseServices.excluirProduto(widget.produto.id!);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Produto excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onClose();
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showErrorSnackBar('Erro ao excluir produto: $e');
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
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
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
          _buildTopBar(),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildSectionTitle('Dados do Produto'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildStatusDropdown()),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _textForm(
                          _nomeController,
                          'Nome do Produto *',
                          'Nome do produto',
                          validator:
                              (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _descricaoController,
                    'Descrição',
                    'Descrição ou detalhes do produto',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 250,
                    child: _textForm(
                      _precoController,
                      'Preço (R\$) *',
                      '0,00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(
                              v.replaceAll('.', '').replaceAll(',', '.'),
                            ) ==
                            null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 45),
                  _buildActionButtons(isWide: true),
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
                  _buildSectionTitle('Dados do Produto'),
                  _buildStatusDropdown(),
                  const SizedBox(height: 24),
                  _textForm(
                    _nomeController,
                    'Nome do Produto *',
                    'Nome do produto',
                    validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _descricaoController,
                    'Descrição',
                    'Descrição ou detalhes do produto',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _textForm(
                    _precoController,
                    'Preço (R\$) *',
                    '0,00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(
                            v.replaceAll('.', '').replaceAll(',', '.'),
                          ) ==
                          null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
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
            'Editar Produto - Cód: ${widget.produto.codigo}',
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
              tooltip: 'Excluir Produto',
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
      items: ['Ativo', 'Inativo'],
      onChanged: (newValue) => setState(() => _selectedStatus = newValue),
      validator: (v) => v == null || v.isEmpty ? 'Selecione um status.' : null,
    );
  }

  Widget _textForm(
    TextEditingController controller,
    String label,
    String hint, {
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    int? maxLines = 1,
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
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _getInputDecoration(hint: hint),
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
    );
  }
}
