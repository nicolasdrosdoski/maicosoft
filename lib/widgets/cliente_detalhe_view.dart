import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maicosoft/services/firebase_services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:maicosoft/models/cliente.dart';
import 'package:url_launcher/url_launcher.dart';

class ClienteDetalheView extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onClose;
  final VoidCallback onEdit;

  const ClienteDetalheView({
    super.key,
    required this.cliente,
    required this.onClose,
    required this.onEdit,
  });

  String _formatCnpjCpf(String? value) {
    if (value == null || value.isEmpty) return '';
    final unmasked = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cliente.tipo == 'Pessoa Física') {
      return MaskTextInputFormatter(mask: '###.###.###-##').maskText(unmasked);
    } else {
      return MaskTextInputFormatter(
        mask: '##.###.###/####-##',
      ).maskText(unmasked);
    }
  }

  String _formatPhone(String? value) {
    if (value == null || value.isEmpty) return '';
    final unmasked = value.replaceAll(RegExp(r'[^\d]'), '');
    return MaskTextInputFormatter(mask: '(##) #####-####').maskText(unmasked);
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Não foi possível abrir $url';
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final FirebaseServices firebaseServices = FirebaseServices();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza de que deseja excluir o cliente "${cliente.nomeFantasia ?? "sem nome"}"? Esta ação não pode ser desfeita.',
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
                  await firebaseServices.excluirCliente(cliente.id!);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  onClose();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir cliente: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? dataFormatada =
        cliente.dataAberturaNascimento != null
            ? DateFormat(
              'dd/MM/yyyy',
            ).format(cliente.dataAberturaNascimento!.toDate())
            : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 45),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(context),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Contato Principal'),
                    _buildStatusItem(cliente.statusCliente),
                    const SizedBox(height: 24),
                    _buildInfoGrid([
                      {
                        'label': 'Nome de Contato',
                        'value': cliente.nomeContato,
                      },
                      {
                        'label': 'E-mail de Contato',
                        'value': cliente.emailContato,
                      },
                      {
                        'label': 'Telefone de Contato',
                        'value': _formatPhone(cliente.telefoneContato),
                      },
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Dados da Empresa'),
                    _buildInfoGrid([
                      {'label': 'Tipo de Pessoa', 'value': cliente.tipo},
                      {
                        'label': 'CNPJ / CPF',
                        'value': _formatCnpjCpf(cliente.cnpjCpf),
                      },
                      {
                        'label':
                            cliente.tipo == 'Pessoa Física'
                                ? 'Nome Completo'
                                : 'Nome Fantasia',
                        'value': cliente.nomeFantasia,
                      },
                      {
                        'label':
                            cliente.tipo == 'Pessoa Física'
                                ? 'Data de Nascimento'
                                : 'Data de Abertura',
                        'value': dataFormatada,
                      },
                      {
                        'label': 'Regime Fiscal/Jurídico',
                        'value': cliente.fiscalJuridico,
                      },
                      {'label': 'Loja', 'value': cliente.loja},
                      {'label': 'Website', 'value': cliente.homePage},
                      {
                        'label': 'Telefone da Empresa',
                        'value': _formatPhone(cliente.telefoneEmpresa),
                      },
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Endereço'),
                    _buildInfoGrid([
                      {'label': 'CEP', 'value': cliente.cep},
                      {'label': 'Endereço', 'value': cliente.endereco},
                      {'label': 'Bairro', 'value': cliente.bairro},
                      {'label': 'Município', 'value': cliente.municipio},
                      {
                        'label': 'Cód. do Município',
                        'value': cliente.codigoMunicipio,
                      },
                      {'label': 'Estado (UF)', 'value': cliente.estado},
                      {'label': 'País', 'value': cliente.pais},
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 15,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onClose),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                '${cliente.nomeFantasia ?? 'Cliente'} - Cód: ${cliente.codigo ?? ''}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () => _showDeleteConfirmationDialog(context),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Excluir', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFc62828),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String status) {
    final Color color;
    final IconData icon;
    switch (status) {
      case 'Ativo':
        color = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'Inativo':
        color = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey.shade700;
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            'Status: $status',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<Map<String, String?>> items) {
    final validItems =
        items
            .where((item) => item['value'] != null && item['value']!.isNotEmpty)
            .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        }
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: crossAxisCount == 1 ? 9 : 6,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: validItems.length,
          itemBuilder: (context, index) {
            final item = validItems[index];
            if (item['label'] == 'Website') {
              return _buildClickableInfoItem(item['label']!, item['value']!);
            }
            return _buildInfoItem(item['label']!, item['value']!);
          },
        );
      },
    );
  }

  Widget _buildClickableInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _launchURL(value),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
