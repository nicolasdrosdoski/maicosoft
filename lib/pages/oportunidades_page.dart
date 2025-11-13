import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:maicosoft/models/cliente.dart';
import 'package:maicosoft/services/firebase_services.dart';
import 'package:maicosoft/widgets/add_oportunidade_view.dart';
import 'package:maicosoft/widgets/edit_cliente_popup.dart';

class OportunidadesPage extends StatefulWidget {
  const OportunidadesPage({super.key});

  @override
  State<OportunidadesPage> createState() => _OportunidadesPageState();
}

class _OportunidadesPageState extends State<OportunidadesPage> {
  final FirebaseServices _firebaseServices = FirebaseServices();
  Stream<List<Cliente>>? _clienteStream;

  bool _isAddingOportunidade = false;
  Cliente? _clienteSendoEditado;

  @override
  void initState() {
    super.initState();
    _clienteStream = _firebaseServices.getOportunidades();
  }

  @override
  Widget build(BuildContext context) {
    if (_clienteSendoEditado != null) {
      return EditClienteView(
        cliente: _clienteSendoEditado!,
        onClose: () => setState(() => _clienteSendoEditado = null),
      );
    } else if (_isAddingOportunidade) {
      return AddOportunidadeView(
        onClose: () => setState(() => _isAddingOportunidade = false),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return _buildNarrowLayout();
          } else {
            return _buildWideLayout();
          }
        },
      );
    }
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 45),
      child: SelectionArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildTopBar(true),
              _buildHeader(),
              Expanded(child: _buildClientList(true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      child: SelectionArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildTopBar(false),
              Expanded(child: _buildClientList(false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Padding(
      padding:
          isWide
              ? const EdgeInsets.symmetric(vertical: 50, horizontal: 60)
              : const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child:
          isWide
              ? Row(children: _topBarContent())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _topBarContent(),
              ),
    );
  }

  List<Widget> _topBarContent() {
    return [
      const Text(
        'Oportunidades',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: 30, height: 20),
      SizedBox(
        height: 49,
        width: 300,
        child: ElevatedButton.icon(
          onPressed: () => setState(() => _isAddingOportunidade = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          label: const Text(
            'Nova Oportunidade',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          icon: const FaIcon(
            FontAwesomeIcons.userPlus,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    ];
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
              _headerText('Nome Contato'),
              _headerText('E-mail'),
              _headerText('Telefone'),
              _headerText('Status'),
              const SizedBox(width: 45),
            ],
          ),
          Divider(color: Colors.grey[500], thickness: 0.3),
        ],
      ),
    );
  }

  Widget _buildClientList(bool isWide) {
    return StreamBuilder<List<Cliente>>(
      stream: _clienteStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return Center(
            child: Text('Erro ao carregar clientes: ${snapshot.error}'),
          );
        }

        if (snapshot.hasData) {
          final clientes = snapshot.data!;

          if (clientes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(50.0),
                child: Text('Nenhum cliente encontrado.'),
              ),
            );
          }

          return ListView.builder(
            padding: isWide ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              return isWide
                  ? _buildWideClienteRow(clientes[index])
                  : _buildNarrowClienteRow(clientes[index]);
            },
          );
        }
        return const Center(child: Text('Nenhum cliente encontrado.'));
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

  Widget _buildWideClienteRow(Cliente cliente) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _cellText(cliente.codigo),
          _cellText(cliente.nomeContato),
          _cellText(cliente.emailContato),
          _cellText(cliente.telefoneContato),
          Expanded(child: _cellStatus(cliente.statusCliente)),
          IconButton(
            onPressed: () => setState(() => _clienteSendoEditado = cliente),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowClienteRow(Cliente cliente) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
                    cliente.nomeContato ?? 'Nome não informado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed:
                      () => setState(() => _clienteSendoEditado = cliente),
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('ID:', cliente.codigo),
            _buildInfoRow('E-mail:', cliente.emailContato),
            _buildInfoRow('Telefone:', cliente.telefoneContato),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: _cellStatus(cliente.statusCliente),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey[800], fontSize: 14),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  ' ${(value == null || value.isEmpty) ? 'Não informado' : value}',
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

  Widget _cellStatus(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color.fromARGB(255, 221, 202, 27),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
