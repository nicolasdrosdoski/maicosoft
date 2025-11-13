import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maicosoft/models/cliente.dart';
import 'package:maicosoft/models/pedido.dart';
import 'package:maicosoft/models/produto.dart';
import 'package:maicosoft/services/firebase_services.dart';

class ItemPedidoForm {
  Produto produto;
  TextEditingController quantidadeController;

  ItemPedidoForm(this.produto)
    : quantidadeController = TextEditingController(text: '1');

  double get subtotal =>
      (produto.preco ?? 0) * (int.tryParse(quantidadeController.text) ?? 1);
}

class AddPedidoView extends StatefulWidget {
  final VoidCallback onClose;

  const AddPedidoView({super.key, required this.onClose});

  @override
  State<AddPedidoView> createState() => _AddPedidoViewState();
}

class _AddPedidoViewState extends State<AddPedidoView> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseServices = FirebaseServices();
  bool _isSaving = false;

  late Stream<List<Cliente>> _clientesAtivosStream;
  late Stream<List<Produto>> _produtosAtivosStream;

  late final String _codigoPedido;
  final _observacoesController = TextEditingController();

  Cliente? _selectedCliente;
  String _selectedStatus = 'Pendente';
  List<ItemPedidoForm> _itensDoPedido = [];
  double _valorTotal = 0.0;

  Produto? _produtoSelecionadoParaAdicionar;

  @override
  void initState() {
    super.initState();
    _codigoPedido = Random().nextInt(999999).toString().padLeft(6, '0');
    _clientesAtivosStream = _firebaseServices.getClientesAtivos();
    _produtosAtivosStream = _firebaseServices.getProdutosAtivos();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    for (var item in _itensDoPedido) {
      item.quantidadeController.dispose();
    }
    super.dispose();
  }

  void _adicionarItem() {
    if (_produtoSelecionadoParaAdicionar != null) {
      if (_itensDoPedido.any(
        (item) => item.produto.id == _produtoSelecionadoParaAdicionar!.id,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto já adicionado.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _itensDoPedido.add(ItemPedidoForm(_produtoSelecionadoParaAdicionar!));
        _produtoSelecionadoParaAdicionar = null;
        _calcularTotal();
      });
    }
  }

  void _removerItem(int index) {
    setState(() {
      _itensDoPedido[index].quantidadeController.dispose();
      _itensDoPedido.removeAt(index);
      _calcularTotal();
    });
  }

  void _calcularTotal() {
    double total = 0.0;
    for (var item in _itensDoPedido) {
      total += item.subtotal;
    }
    setState(() {
      _valorTotal = total;
    });
  }

  Future<void> _salvarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um cliente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_itensDoPedido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, adicione pelo menos um produto ao pedido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<PedidoItem> itensFinais =
          _itensDoPedido.map((itemForm) {
            return PedidoItem(
              produtoId: itemForm.produto.id!,
              produtoNome: itemForm.produto.nome ?? 'N/A',
              quantidade: int.tryParse(itemForm.quantidadeController.text) ?? 1,
              precoUnitario: itemForm.produto.preco ?? 0,
            );
          }).toList();

      final novoPedido = Pedido(
        codigo: _codigoPedido,
        clienteId: _selectedCliente!.id!,
        clienteNome:
            _selectedCliente!.nomeFantasia ??
            _selectedCliente!.nomeContato ??
            'N/A',
        itens: itensFinais,
        valorTotal: _valorTotal,
        status: _selectedStatus,
        observacoes: _observacoesController.text.trim(),
      );
      await _firebaseServices.salvarNovoPedido(novoPedido);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar pedido: $e'),
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
        final isWide = constraints.maxWidth > 800;
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
                    children: [
                      _buildSectionTitle('Dados do Pedido'),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildStatusDropdown()),
                            const SizedBox(width: 24),
                            SizedBox(width: 200, child: _codigoField()),
                          ],
                        )
                      else ...[
                        _buildStatusDropdown(),
                        const SizedBox(height: 24),
                        _codigoField(),
                      ],
                      const SizedBox(height: 24),
                      _buildClienteDropdown(),
                      const SizedBox(height: 32),

                      _buildSectionTitle('Itens do Pedido'),
                      _buildItensSection(),
                      const SizedBox(height: 24),
                      _buildTotalSection(),

                      const SizedBox(height: 32),
                      _buildSectionTitle('Observações'),
                      _textForm(
                        controller: _observacoesController,
                        label: 'Observações',
                        hint: 'Detalhes, notas de entrega, etc.',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 40),
                      _buildActionButtons(isWide: isWide),
                      const SizedBox(height: 20),
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
        const Text(
          'Cadastrar Pedido',
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

  Widget _buildClienteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cliente *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Cliente>>(
          stream: _clientesAtivosStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return const Text('Erro ao carregar clientes');
            }
            final clientes = snapshot.data ?? [];
            return DropdownButtonFormField<Cliente>(
              value: _selectedCliente,
              onChanged: (Cliente? newValue) {
                setState(() {
                  _selectedCliente = newValue;
                });
              },
              items:
                  clientes.map((Cliente cliente) {
                    return DropdownMenuItem<Cliente>(
                      value: cliente,
                      child: Text(
                        cliente.nomeFantasia ??
                            cliente.nomeContato ??
                            'Cliente sem nome',
                      ),
                    );
                  }).toList(),
              decoration: _getInputDecoration(hint: 'Selecione um cliente'),
              validator: (v) => v == null ? 'Campo obrigatório' : null,
              isExpanded: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildItensSection() {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: StreamBuilder<List<Produto>>(
                  stream: _produtosAtivosStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }

                    if (snapshot.hasError) {
                      debugPrint(
                        "Erro ao carregar produtos: ${snapshot.error}",
                      );
                      return TextFormField(
                        decoration: _getInputDecoration(
                          hint: 'Erro ao carregar produtos',
                        ).copyWith(
                          errorText: 'Erro: ${snapshot.error}',
                          errorMaxLines: 3,
                        ),
                        readOnly: true,
                      );
                    }

                    final produtos = snapshot.data ?? [];
                    if (produtos.isEmpty) {
                      return TextFormField(
                        decoration: _getInputDecoration(
                          hint: 'Nenhum produto "Ativo" encontrado',
                        ),
                        readOnly: true,
                      );
                    }

                    return DropdownButtonFormField<Produto>(
                      value: _produtoSelecionadoParaAdicionar,
                      onChanged: (Produto? newValue) {
                        setState(() {
                          _produtoSelecionadoParaAdicionar = newValue;
                        });
                      },
                      items:
                          produtos.map((Produto produto) {
                            return DropdownMenuItem<Produto>(
                              value: produto,
                              child: Text(
                                "${produto.nome} (${formatadorPreco.format(produto.preco ?? 0)})",
                              ),
                            );
                          }).toList(),
                      decoration: _getInputDecoration(
                        hint: 'Selecione um produto',
                      ),
                      isExpanded: true,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 49,
                child: ElevatedButton.icon(
                  onPressed: _adicionarItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _itensDoPedido.length,
            itemBuilder: (context, index) {
              final item = _itensDoPedido[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.produto.nome ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatadorPreco.format(item.produto.preco ?? 0),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _textForm(
                        controller: item.quantidadeController,
                        label: 'Qtd.',
                        hint: '1',
                        isDense: true,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calcularTotal(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removerItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_itensDoPedido.isEmpty)
            const Center(
              child: Text(
                'Nenhum produto adicionado.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Valor Total do Pedido:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
            ).format(_valorTotal),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFc62828),
            ),
          ),
        ],
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
      child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
    );

    final saveButton = ElevatedButton(
      onPressed: _isSaving ? null : _salvarPedido,
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
            _codigoPedido,
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

  Widget _buildStatusDropdown() {
    return _buildDropdown<String>(
      label: 'Status *',
      hint: 'Selecione o Status',
      value: _selectedStatus,
      items: ['Pendente', 'Em Processamento', 'Concluído', 'Cancelado'],
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _selectedStatus = newValue);
        }
      },
      validator: (v) => v == null || v.isEmpty ? 'Selecione um status.' : null,
    );
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

  Widget _textForm({
    required TextEditingController controller,
    required String label,
    required String hint,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool isDense = false,
    void Function(String)? onChanged,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: _getInputDecoration(hint: hint, isDense: isDense),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration({
    required String hint,
    bool isDense = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      isDense: isDense,
      contentPadding:
          isDense
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12)
              : null,
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
