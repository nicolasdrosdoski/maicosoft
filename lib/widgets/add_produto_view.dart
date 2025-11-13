import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maicosoft/models/produto.dart';
import 'package:maicosoft/services/firebase_services.dart';

class AddProdutoView extends StatefulWidget {
  final VoidCallback onClose;

  const AddProdutoView({super.key, required this.onClose});

  @override
  State<AddProdutoView> createState() => _AddProdutoViewState();
}

class _AddProdutoViewState extends State<AddProdutoView> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseServices = FirebaseServices();
  bool _isSaving = false;

  late final String _codigoProduto;
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codigoProduto = Random().nextInt(999999).toString().padLeft(6, '0');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final novoProduto = Produto(
        codigo: _codigoProduto,
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim(),
        preco: double.tryParse(_precoController.text.replaceAll(',', '.')),
        status: 'Ativo',
      );

      await _firebaseServices.salvarNovoProduto(novoProduto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar produto: $e'),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Container(
          padding: EdgeInsets.symmetric(
            vertical: 30,
            horizontal: isWide ? 45 : 24,
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 32),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children:
                        isWide ? _buildWideFields() : _buildNarrowFields(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(isWide: isWide),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildWideFields() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _textForm(
              controller: _nomeController,
              label: 'Nome do Produto *',
              hint: 'Nome do produto',
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(width: 200, child: _codigoField()),
        ],
      ),
      const SizedBox(height: 24),
      _textForm(
        controller: _descricaoController,
        label: 'Descrição',
        hint: 'Descrição ou detalhes do produto',
        maxLines: 3,
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: 250,
        child: _textForm(
          controller: _precoController,
          label: 'Preço (R\$) *',
          hint: '0,00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Campo obrigatório';
            if (double.tryParse(v.replaceAll(',', '.')) == null) {
              return 'Valor inválido';
            }
            return null;
          },
        ),
      ),
    ];
  }

  List<Widget> _buildNarrowFields() {
    return [
      _textForm(
        controller: _nomeController,
        label: 'Nome do Produto *',
        hint: 'Nome do produto',
        validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
      ),
      const SizedBox(height: 24),
      _codigoField(),
      const SizedBox(height: 24),
      _textForm(
        controller: _descricaoController,
        label: 'Descrição',
        hint: 'Descrição ou detalhes do produto',
        maxLines: 3,
      ),
      const SizedBox(height: 24),
      _textForm(
        controller: _precoController,
        label: 'Preço (R\$) *',
        hint: '0,00',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
        validator: (v) {
          if (v == null || v.isEmpty) return 'Campo obrigatório';
          if (double.tryParse(v.replaceAll(',', '.')) == null) {
            return 'Valor inválido';
          }
          return null;
        },
      ),
    ];
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Cadastrar Produto',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close_outlined),
        ),
      ],
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
      child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
    );

    final saveButton = ElevatedButton(
      onPressed: _isSaving ? null : _salvarProduto,
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

  Widget _codigoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Código',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            _codigoProduto,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _textForm({
    required TextEditingController controller,
    required String label,
    required String hint,
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

  InputDecoration _getInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
      ),
    );
  }
}
