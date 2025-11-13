import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maicosoft/models/produto.dart';
import 'package:maicosoft/services/firebase_services.dart';
import 'package:maicosoft/widgets/add_produto_view.dart';
import 'package:maicosoft/widgets/edit_produto_view.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final TextEditingController _searchController = TextEditingController();
  Stream<List<Produto>>? _produtoStream;

  Produto? _produtoSendoEditado;
  bool _isAddingProduto = false;

  String _statusFiltro = 'Todos';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _produtoStream = _firebaseServices.getProdutos();
    _searchController.addListener(_onFilterChanged);
  }

  void _onFilterChanged() {
    setState(() {
      _produtoStream = _firebaseServices.getProdutos(
        searchQuery: _searchController.text,
        status: _statusFiltro,
      );
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _statusFiltro = 'Todos';
    });
    _onFilterChanged();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_produtoSendoEditado != null) {
      return EditProdutoView(
        produto: _produtoSendoEditado!,
        onClose: () => setState(() => _produtoSendoEditado = null),
      );
    } else if (_isAddingProduto) {
      return AddProdutoView(
        onClose: () => setState(() => _isAddingProduto = false),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: isWide ? 30 : 15,
              horizontal: isWide ? 45 : 16,
            ),
            child: SelectionArea(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildTopBar(isWide),
                    if (_showFilters) _buildFilterBar(isWide),
                    if (isWide) _buildHeader(),
                    Expanded(child: _buildProductList(isWide)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildTopBar(bool isWide) {
    return Padding(
      padding:
          isWide
              ? const EdgeInsets.fromLTRB(60, 50, 60, 20)
              : const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child:
          isWide
              ? Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Produtos',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 45),
                  _buildAddButton(),
                  Row(children: _topBarContent(isWide: true)),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._topBarContent(isWide: false),
                  const SizedBox(height: 15),
                  _buildAddButton(isWide: false),
                ],
              ),
    );
  }

  Widget _buildAddButton({bool isWide = true}) {
    return SizedBox(
      height: 49,
      width: isWide ? 250 : double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _isAddingProduto = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        label: const Text(
          'Novo Produto',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        icon: const FaIcon(
          FontAwesomeIcons.plus,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  List<Widget> _topBarContent({bool isWide = true}) {
    return [
      SizedBox(width: isWide ? 30 : 0, height: isWide ? 0 : 15),
      // SizedBox(
      //   width: 300,
      //   child: TextField(
      //     controller: _searchController,
      //     decoration: InputDecoration(
      //       hintText: 'Buscar por nome do produto...',
      //       prefixIcon: const Icon(Icons.search),
      //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      //       contentPadding: const EdgeInsets.symmetric(
      //         vertical: 10,
      //         horizontal: 20,
      //       ),
      //     ),
      //   ),
      // ),
      SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 10),
      TextButton.icon(
        icon: Icon(
          _showFilters
              ? Icons.filter_alt_off_outlined
              : Icons.filter_alt_outlined,
        ),
        label: const Text('Filtros'),
        onPressed: () => setState(() => _showFilters = !_showFilters),
      ),
    ];
  }

  Widget _buildFilterBar(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Wrap(
          spacing: 15.0,
          runSpacing: 15.0,
          alignment: WrapAlignment.start,
          children: [
            _buildDropdownFilter(
              label: 'Status',
              value: _statusFiltro,
              items: ['Todos', 'Ativo', 'Inativo'],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statusFiltro = value);
                  _onFilterChanged();
                }
              },
            ),
            TextButton(
              onPressed: _clearFilters,
              child: const Text("Limpar Filtros"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),
        ),
        items:
            items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerText('ID'),
              _headerText('Nome do Produto'),
              _headerText('Preço (R\$)'),
              _headerText('Status'),
              const SizedBox(width: 45),
            ],
          ),
          Divider(color: Colors.grey[500], thickness: 0.3),
        ],
      ),
    );
  }

  Widget _buildProductList(bool isWide) {
    final formatadorPreco = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    return StreamBuilder<List<Produto>>(
      stream: _produtoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar produtos: ${snapshot.error}'),
          );
        }
        final produtos = snapshot.data;
        if (produtos == null || produtos.isEmpty) {
          return const Center(child: Text('Nenhum produto encontrado.'));
        }

        return ListView.builder(
          padding: isWide ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
          itemCount: produtos.length,
          itemBuilder: (context, index) {
            return isWide
                ? _buildWideProdutoRow(produtos[index], formatadorPreco)
                : _buildNarrowProdutoRow(produtos[index], formatadorPreco);
          },
        );
      },
    );
  }

  Widget _headerText(String text) => Expanded(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Colors.grey[500],
          ),
        ),
      ),
    ),
  );

  Widget _buildWideProdutoRow(Produto produto, NumberFormat formatador) {
    return InkWell(
      onTap: () => setState(() => _produtoSendoEditado = produto),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _cellText(produto.codigo),
            _cellText(produto.nome),
            _cellText(
              produto.preco != null ? formatador.format(produto.preco) : '-',
            ),
            _cellStatus(produto.status),
            const SizedBox(
              width: 45,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowProdutoRow(Produto produto, NumberFormat formatador) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: InkWell(
        onTap: () => setState(() => _produtoSendoEditado = produto),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      produto.nome ?? 'Nome não informado',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${produto.codigo ?? "N/A"}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Divider(),
              _buildInfoRow(
                'Preço:',
                produto.preco != null ? formatador.format(produto.preco) : '-',
              ),
              const SizedBox(height: 10),
              _cellStatus(produto.status, isWide: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: Colors.grey[800], fontSize: 14),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: (value == null || value.isEmpty) ? 'Não informado' : value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cellText(String? text) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        (text == null || text.isEmpty) ? 'Não informado' : text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
      ),
    ),
  );

  Widget _cellStatus(String text, {bool isWide = true}) {
    final Color color;
    final Color textColor;
    final Color colorBorda;
    switch (text) {
      case 'Ativo':
        color = Colors.green.shade100;
        textColor = Colors.green.shade800;
        colorBorda = Colors.green.shade800;
        break;
      case 'Inativo':
        color = Colors.red.shade100;
        textColor = Colors.red.shade800;
        colorBorda = Colors.red.shade800;
        break;
      default:
        color = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        colorBorda = Colors.grey.shade800;
    }

    Widget statusWidget = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colorBorda, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );

    if (isWide) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
          child: statusWidget,
        ),
      );
    }
    return Align(alignment: Alignment.centerLeft, child: statusWidget);
  }
}
