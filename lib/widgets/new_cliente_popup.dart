// import 'package:flutter/material.dart';
// import 'package:maicosoft/models/cliente.dart';
// import 'package:maicosoft/services/firebase_services.dart';

// class NewClientePopUp extends StatefulWidget {
//   const NewClientePopUp({super.key});

//   @override
//   State<NewClientePopUp> createState() => _NewClientePopUpState();
// }

// class _NewClientePopUpState extends State<NewClientePopUp> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _cnpjCpfController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _telefoneController = TextEditingController();
//   final TextEditingController _nomeController = TextEditingController();

//   bool _isSaving = false;

//   final FirebaseServices _firebaseServices = FirebaseServices();

//   Future<void> _salvarNovoCliente() async {
//     final isFormValidate = _formKey.currentState!.validate();
//     if (!isFormValidate) return;

//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       final novoCliente = Cliente(
//         nomeContato: _nomeController.text.trim(),
//         emailContato: _emailController.text.trim(),
//         telefoneContato: _telefoneController.text.trim(),
//         cnpjCpf: _cnpjCpfController.text.trim(),
//       );

//       await _firebaseServices.salvarNovoCliente(novoCliente);

//       if (!mounted) return;
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Campanha salva com sucesso!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erro ao salvar novo cliente: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSaving = false;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _cnpjCpfController.dispose();
//     _emailController.dispose();
//     _telefoneController.dispose();
//     _nomeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 500,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.onSecondary,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             spacing: 14,
//             children: [
//               Text(
//                 'Adicionar Novo Cliente',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).colorScheme.onSurface,
//                 ),
//               ),

//               _textForm(
//                 _nomeController,
//                 'Nome de Contato *',
//                 Icon(Icons.person_outline),
//                 (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor, insira o nome de contato.';
//                   }
//                   return null;
//                 },
//               ),

//               _textForm(
//                 _emailController,
//                 'E-mail de Contato *',
//                 Icon(Icons.email_outlined),
//                 (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor, insira o e-mail de contato.';
//                   }
//                   return null;
//                 },
//               ),

//               _textForm(
//                 _cnpjCpfController,
//                 'CPF/CNPJ',
//                 Icon(Icons.badge_outlined),
//                 (value) {
//                   return null;
//                 },
//               ),

//               _textForm(
//                 _telefoneController,
//                 'Telefone de Contato',
//                 Icon(Icons.phone_android_outlined),
//                 (value) {
//                   return null;
//                 },
//               ),

//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed:
//                         _isSaving
//                             ? null
//                             : () {
//                               Navigator.of(context).pop();
//                             },
//                     child: const Text('Cancelar'),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: _isSaving ? null : _salvarNovoCliente,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Theme.of(context).colorScheme.primary,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 24,
//                         vertical: 12,
//                       ),
//                     ),
//                     child:
//                         _isSaving
//                             ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2.0,
//                               ),
//                             )
//                             : const Text('Salvar'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _textForm(
//     TextEditingController controller,
//     String nomeCampo,
//     Icon icon,
//     FormFieldValidator validator,
//   ) {
//     return TextFormField(
//       controller: controller,

//       decoration: InputDecoration(
//         labelText: nomeCampo,
//         labelStyle: TextStyle(color: Colors.grey[700]),

//         filled: true,
//         fillColor: Colors.grey[100],

//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
//         ),

//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: BorderSide(
//             color: Theme.of(context).colorScheme.primary,
//             width: 2.0,
//           ),
//         ),

//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
//         ),

//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12.0),
//           borderSide: BorderSide(color: Colors.red.shade600, width: 2.0),
//         ),

//         prefixIcon: icon,
//       ),

//       validator: validator,

//       style: TextStyle(color: Colors.black87),
//     );
//   }
// }
