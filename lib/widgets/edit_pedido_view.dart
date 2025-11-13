import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maicosoft/models/pedido.dart';
import 'package:maicosoft/services/firebase_services.dart';

class EditPedidoView extends StatefulWidget {
  final Pedido pedido;
  final VoidCallback onClose;

  const EditPedidoView({
    super.key,
    required this.pedido,
    required this.onClose,
  });

  @override
  State<EditPedidoView> createState() => _EditPedidoViewState();
}

class _EditPedidoViewState extends State<EditPedidoView> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _firebaseServices = FirebaseServices();
  bool _isSaving = false;

  String? _selectedStatus;
  late TextEditingController _observacoesController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.pedido.status;
    _observacoesController = TextEditingController(
      text: widget.pedido.observacoes ?? '',
    );
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
        'status': _selectedStatus,
        'observacoes': _observacoesController.text.trim(),
      };

      await _firebaseServices.atualizarPedido(widget.pedido.id!, updatedData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onClose();
    } catch (e) {
      _showErrorSnackBar('Erro ao atualizar pedido: $e');
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
                  await _firebaseServices.excluirPedido(widget.pedido.id!);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pedido excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onClose();
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showErrorSnackBar('Erro ao excluir pedido: $e');
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
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;
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
              const SizedBox(height: 16),
              Divider(color: Colors.grey[200]),
              const SizedBox(height: 16),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _buildSectionTitle(
                        'Informações do Pedido (Não Editável)',
                      ),
                      _buildInfoItem('Cliente:', widget.pedido.clienteNome),
                      _buildInfoItem(
                        'Valor Total:',
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(widget.pedido.valorTotal),
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyItemList(),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Campos Editáveis'),
                      _buildStatusDropdown(),
                      const SizedBox(height: 24),
                      _textForm(
                        _observacoesController,
                        'Observações',
                        'Detalhes, notas de entrega, etc.',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 45),
                      _buildActionButtons(isWide: isWide),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Editar Pedido - Cód: ${widget.pedido.codigo}',
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
              tooltip: 'Excluir Pedido',
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

  Widget _buildReadOnlyItemList() {
    final formatadorPreco = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Itens Inclusos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.pedido.itens.length,
            itemBuilder: (context, index) {
              final item = widget.pedido.itens[index];
              return ListTile(
                title: Text(item.produtoNome),
                subtitle: Text(
                  'Qtd: ${item.quantidade} x ${formatadorPreco.format(item.precoUnitario)}',
                ),
                trailing: Text(
                  formatadorPreco.format(item.quantidade * item.precoUnitario),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: ' $value'),
          ],
        ),
        overflow: TextOverflow.ellipsis,
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
      items: ['Pendente', 'Em Processamento', 'Concluído', 'Cancelado'],
      onChanged: (newValue) => setState(() => _selectedStatus = newValue),
      validator: (v) => v == null || v.isEmpty ? 'Selecione um status.' : null,
    );
  }

  Widget _textForm(
    TextEditingController controller,
    String label,
    String hint, {
    FormFieldValidator<String>? validator,
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
