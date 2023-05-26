// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:work/colors.dart';
// import 'package:work/common/widgets/loader.dart';
// import 'package:work/models/document_model.dart';
// import 'package:work/models/error_model.dart';
// import 'package:work/repository/auth_repository.dart';
// import 'package:work/repository/document_repository.dart';
// import 'package:work/repository/socket_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_quill/flutter_quill.dart' as quill;
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:routemaster/routemaster.dart';
// import 'package:filesystem_picker/filesystem_picker.dart';
// import 'package:flutter_quill/extensions.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
// import 'package:path/path.dart';
//
// import '../common/universal_ui.dart';
//
// class DocumentScreen extends ConsumerStatefulWidget {
//   final String id;
//   const DocumentScreen({
//     Key? key,
//     required this.id,
//   }) : super(key: key);
//
//   @override
//   ConsumerState<ConsumerStatefulWidget> createState() => _DocumentScreenState();
// }
//
// class _DocumentScreenState extends ConsumerState<DocumentScreen> {
//   final FocusNode _focusNode = FocusNode();
//   TextEditingController titleController = TextEditingController(text: 'Untitled Document');
//   quill.QuillController? _controller;
//   ErrorModel? errorModel;
//   SocketRepository socketRepository = SocketRepository();
//
//   @override
//   void initState() {
//     super.initState();
//     socketRepository.joinRoom(widget.id);
//     fetchDocumentData();
//
//     socketRepository.changeListener((data) {
//       _controller?.compose(
//         quill.Delta.fromJson(data['delta']),
//         _controller?.selection ?? const TextSelection.collapsed(offset: 0),
//         quill.ChangeSource.REMOTE,
//       );
//     });
//
//     Timer.periodic(const Duration(seconds: 2), (timer) {
//       socketRepository.autoSave(<String, dynamic>{
//         'delta': _controller!.document.toDelta(),
//         'room': widget.id,
//       });
//     });
//   }
//
//
//
//   void fetchDocumentData() async {
//     errorModel = await ref.read(documentRepositoryProvider).getDocumentById(
//           ref.read(userProvider)!.token,
//           widget.id,
//         );
//
//     if (errorModel!.data != null) {
//       titleController.text = (errorModel!.data as DocumentModel).title;
//       _controller = quill.QuillController(
//         document: errorModel!.data.content.isEmpty
//             ? quill.Document()
//             : quill.Document.fromDelta(
//                 quill.Delta.fromJson(errorModel!.data.content),
//               ),
//         selection: const TextSelection.collapsed(offset: 0),
//       );
//       setState(() {});
//     }
//
//     _controller!.document.changes.listen((event) {
//       if (event.change == quill.ChangeSource.LOCAL) {
//         Map<String, dynamic> map = {
//           'delta': event.source,
//           'room': widget.id,
//         };
//         socketRepository.typing(map);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     titleController.dispose();
//     _controller!.dispose();
//   }
//
//   void updateTitle(WidgetRef ref, String title) {
//     ref.read(documentRepositoryProvider).updateTitle(
//           token: ref.read(userProvider)!.token,
//           id: widget.id,
//           title: title,
//         );
//   }
//   Future<String?> openFileSystemPickerForDesktop(BuildContext context) async {
//     return await FilesystemPicker.open(
//       context: context,
//       rootDirectory: await getApplicationDocumentsDirectory(),
//       fsType: FilesystemType.file,
//       fileTileSelectMode: FileTileSelectMode.wholeTile,
//     );
//   }
//   Future<String> _onImagePickCallback(File file) async {
//     // Copies the picked file from temporary cache to applications directory
//     final appDocDir = await getApplicationDocumentsDirectory();
//     final copiedFile =
//     await file.copy('${appDocDir.path}/${basename(file.path)}');
//     print('copy');
//     return copiedFile.path.toString();
//   }
//   Future<String> _onImagePaste(Uint8List imageBytes) async {
//     // Saves the image to applications directory
//     final appDocDir = await getApplicationDocumentsDirectory();
//     final file = await File(
//         '${appDocDir.path}/${basename('${DateTime.now().millisecondsSinceEpoch}.png')}')
//         .writeAsBytes(imageBytes, flush: true);
//     return file.path.toString();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_controller == null) {
//       return const Scaffold(body: Loader());
//     }
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: kWhiteColor,
//         elevation: 0,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 Clipboard.setData(ClipboardData(text: 'http://localhost:3000/#/document/${widget.id}')).then(
//                   (value) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                           'Link copied!',
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//               icon: const Icon(
//                 Icons.lock,
//                 size: 16,
//               ),
//               label: const Text('Share'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: kBlueColor,
//               ),
//             ),
//           ),
//         ],
//         title: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 9.0),
//           child: Row(
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   Routemaster.of(context).replace('/');
//                 },
//                 child: Image.asset(
//                   'assets/images/docs-logo.png',
//                   height: 40,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               SizedBox(
//                 width: 180,
//                 child: TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(
//                     border: InputBorder.none,
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(
//                         color: kBlueColor,
//                       ),
//                     ),
//                     contentPadding: EdgeInsets.only(left: 10),
//                   ),
//                   onSubmitted: (value) => updateTitle(ref, value),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             decoration: BoxDecoration(
//               border: Border.all(
//                 color: kGreyColor,
//                 width: 0.1,
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Center(
//         child: Column(
//           children: [
//             const SizedBox(height: 10),
//             quill.QuillToolbar.basic(controller: _controller!,
//               embedButtons: FlutterQuillEmbeds.buttons(
//                 onImagePickCallback: _onImagePickCallback,
//                 filePickImpl: openFileSystemPickerForDesktop,
//               ),
//               showAlignmentButtons: true,
//               afterButtonPressed: _focusNode.requestFocus,
//             ),
//             const SizedBox(height: 10),
//             Expanded(
//               child: SizedBox(
//                 width: 750,
//                 child: Card(
//                   color: kWhiteColor,
//                   elevation: 5,
//                   child: Padding(
//                     padding: const EdgeInsets.all(30.0),
//                     child: MouseRegion(
//                       cursor: SystemMouseCursors.text,
//                       child: quill.QuillEditor(
//
//                         controller: _controller!,
//                         readOnly: false,
//                         placeholder: 'Add content',
//                         expands: false,
//                         padding: EdgeInsets.zero,
//                         scrollController: ScrollController(),
//                         scrollable: true,
//                         onImagePaste: _onImagePaste,
//                         focusNode: _focusNode,
//                         autoFocus: false,
//                           customStyles: quill.DefaultStyles(
//                             h1: quill.DefaultTextBlockStyle(
//                                 const TextStyle(
//                                   fontSize: 32,
//                                   color: Colors.black,
//                                   height: 1.15,
//                                   fontWeight: FontWeight.w300,
//                                 ),
//                                 const quill.VerticalSpacing(16, 0),
//                                 const quill.VerticalSpacing(0, 0),
//                                 null),
//                             sizeSmall: const TextStyle(fontSize: 9),
//                           ),
//                           embedBuilders: [
//                             ...defaultEmbedBuildersWeb,
//                             NotesEmbedBuilder(addEditNote: _addEditNote),
//                           ]
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//
//   }
//   Future<void> _addEditNote(BuildContext context, {quill.Document? document}) async {
//     final isEditing = document != null;
//     final quillEditorController = quill.QuillController(
//       document: document ?? quill.Document(),
//       selection: const TextSelection.collapsed(offset: 0),
//     );
//
//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         titlePadding: const EdgeInsets.only(left: 16, top: 8),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text('${isEditing ? 'Edit' : 'Add'} note'),
//             IconButton(
//               onPressed: () => Navigator.of(context).pop(),
//               icon: const Icon(Icons.close),
//             )
//           ],
//         ),
//         content: quill.QuillEditor.basic(
//           controller: quillEditorController,
//           readOnly: false,
//         ),
//       ),
//     );
//
//     if (quillEditorController.document.isEmpty()) return;
//
//     final block = quill.BlockEmbed.custom(
//       NotesBlockEmbed.fromDocument(quillEditorController.document),
//     );
//     final controller = _controller!;
//     final index = controller.selection.baseOffset;
//     final length = controller.selection.extentOffset - index;
//
//     if (isEditing) {
//       final offset =
//           quill.getEmbedNode(controller, controller.selection.start).offset;
//       controller.replaceText(
//           offset, 1, block, TextSelection.collapsed(offset: offset));
//     } else {
//       controller.replaceText(index, length, block, null);
//     }
//   }
// }
// class NotesEmbedBuilder extends quill.EmbedBuilder {
//   NotesEmbedBuilder({required this.addEditNote});
//
//   Future<void> Function(BuildContext context, {quill.Document? document}) addEditNote;
//
//   @override
//   String get key => 'notes';
//
//   @override
//   Widget build(
//       BuildContext context,
//       quill.QuillController controller,
//       Embed node,
//       bool readOnly,
//       bool inline,
//       ) {
//     final notes = NotesBlockEmbed(node.value.data).document;
//
//     return Material(
//       color: Colors.transparent,
//       child: ListTile(
//         title: Text(
//           notes.toPlainText().replaceAll('\n', ' '),
//           maxLines: 3,
//           overflow: TextOverflow.ellipsis,
//         ),
//         leading: const Icon(Icons.notes),
//         onTap: () => addEditNote(context, document: notes),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//           side: const BorderSide(color: Colors.grey),
//         ),
//       ),
//     );
//   }
// }
//
// class NotesBlockEmbed extends quill.CustomBlockEmbed {
//   const NotesBlockEmbed(String value) : super(noteType, value);
//
//   static const String noteType = 'notes';
//
//   static NotesBlockEmbed fromDocument(quill.Document document) =>
//       NotesBlockEmbed(jsonEncode(document.toDelta().toJson()));
//
//   quill.Document get document => quill.Document.fromJson(jsonDecode(data));
// }
