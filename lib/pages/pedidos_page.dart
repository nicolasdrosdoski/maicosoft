import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maicosoft/models/pedido.dart';
import 'package:maicosoft/services/firebase_services.dart';
import 'package:maicosoft/widgets/add_pedido_view.dart';
import 'package:maicosoft/widgets/edit_pedido_view.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  final TextEditingController _searchController = TextEditingController();
  Stream<List<Pedido>>? _pedidoStream;

  Pedido? _pedidoSendoEditado;
  bool _isAddingPedido = false;

  String _statusFiltro = 'Todos';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _pedidoStream = _firebaseServices.getPedidos();
    _searchController.addListener(_onFilterChanged);
  }

  void _onFilterChanged() {
    setState(() {
      _pedidoStream = _firebaseServices.getPedidos(
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
    if (_pedidoSendoEditado != null) {
      return EditPedidoView(
        pedido: _pedidoSendoEditado!,
        onClose: () => setState(() => _pedidoSendoEditado = null),
      );
    } else if (_isAddingPedido) {
      return AddPedidoView(
        onClose: () => setState(() => _isAddingPedido = false),
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
                    Expanded(child: _buildPedidoList(isWide)),
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
                    'Pedidos',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 45),
                  _buildAddButton(),
                  ..._topBarContent(isWide: true),
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
        onPressed: () => setState(() => _isAddingPedido = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        label: const Text(
          'Novo Pedido',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        icon: const FaIcon(
          FontAwesomeIcons.truckFast,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  List<Widget> _topBarContent({bool isWide = true}) {
    return [
      SizedBox(width: isWide ? 30 : 0, height: isWide ? 0 : 15),
      SizedBox(
        width: 300,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por cliente ou Cód...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 20,
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.all(10),
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
              items: [
                'Todos',
                'Pendente',
                'Em Processamento',
                'Concluído',
                'Cancelado',
              ],
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
      width: 220,
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
              _headerText('Cód. Pedido'),
              _headerText('Cliente'),
              _headerText('Data'),
              _headerText('Valor Total (R\$)'),
              _headerText('Status'),
              const SizedBox(width: 45),
            ],
          ),
          Divider(color: Colors.grey[500], thickness: 0.3),
        ],
      ),
    );
  }

  Widget _buildPedidoList(bool isWide) {
    final formatadorPreco = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    final formatadorData = DateFormat('dd/MM/yyyy');

    return StreamBuilder<List<Pedido>>(
      stream: _pedidoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar pedidos: ${snapshot.error}'),
          );
        }
        final pedidos = snapshot.data;
        if (pedidos == null || pedidos.isEmpty) {
          return const Center(child: Text('Nenhum pedido encontrado.'));
        }

        return ListView.builder(
          padding: isWide ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
          itemCount: pedidos.length,
          itemBuilder: (context, index) {
            return isWide
                ? _buildWidePedidoRow(
                  pedidos[index],
                  formatadorPreco,
                  formatadorData,
                )
                : _buildNarrowPedidoRow(
                  pedidos[index],
                  formatadorPreco,
                  formatadorData,
                );
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

  Widget _buildWidePedidoRow(
    Pedido pedido,
    NumberFormat formatadorPreco,
    DateFormat formatadorData,
  ) {
    return InkWell(
      onTap: () => setState(() => _pedidoSendoEditado = pedido),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _cellText(pedido.codigo),
            _cellText(pedido.clienteNome),
            _cellText(
              pedido.dataCriacao != null
                  ? formatadorData.format(pedido.dataCriacao!.toDate())
                  : '-',
            ),
            _cellText(formatadorPreco.format(pedido.valorTotal)),
            _cellStatus(pedido.status),
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

  Widget _buildNarrowPedidoRow(
    Pedido pedido,
    NumberFormat formatadorPreco,
    DateFormat formatadorData,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: InkWell(
        onTap: () => setState(() => _pedidoSendoEditado = pedido),
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
                      'Pedido #${pedido.codigo ?? "N/A"}',
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
                'Cliente: ${pedido.clienteNome}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const Divider(),
              _buildInfoRow(
                'Data:',
                pedido.dataCriacao != null
                    ? formatadorData.format(pedido.dataCriacao!.toDate())
                    : '-',
              ),
              _buildInfoRow(
                'Valor:',
                formatadorPreco.format(pedido.valorTotal),
              ),
              const SizedBox(height: 10),
              _cellStatus(pedido.status, isWide: false),
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
      case 'Concluído':
        color = Colors.green.shade100;
        textColor = Colors.green.shade800;
        colorBorda = Colors.green.shade800;
        break;
      case 'Cancelado':
        color = Colors.red.shade100;
        textColor = Colors.red.shade800;
        colorBorda = Colors.red.shade800;
        break;
      case 'Em Processamento':
        color = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        colorBorda = Colors.blue.shade800;
        break;
      case 'Pendente':
      default:
        color = Colors.yellow.shade100;
        textColor = Colors.yellow.shade900;
        colorBorda = Colors.yellow.shade800;
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
