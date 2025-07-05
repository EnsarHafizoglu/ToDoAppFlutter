import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr_TR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final CollectionReference todos =
      FirebaseFirestore.instance.collection('todos');
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedIcon;

  final List<Map<String, dynamic>> _iconOptions = [
    {'emoji': '🛒', 'label': 'Market'},
    {'emoji': '📚', 'label': 'Kitap'},
    {'emoji': '🏠', 'label': 'Ev'},
    {'emoji': '💻', 'label': 'İş'},
    {'emoji': '📅', 'label': 'Etkinlik'},
    {'emoji': '📞', 'label': 'Ara'},
    {'emoji': '✈️', 'label': 'Seyahat'},
    {'emoji': '⏰', 'label': 'Alarm'},
    {'emoji': '📦', 'label': 'Kargo'},
    {'emoji': '❤️', 'label': 'Sevgi'},
  ];

  void _addTodo() {
    if (_selectedIcon != null &&
        _titleController.text.isNotEmpty &&
        _subtitleController.text.isNotEmpty) {
      todos.add({
        'icon': _selectedIcon,
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'timestamp': _selectedDate,
        'completed': false,
      });
      _titleController.clear();
      _subtitleController.clear();
      _selectedDate = null;
      _selectedIcon = null;
      Navigator.of(context).pop();
    }
  }

  void _deleteTodo(String id) {
    todos.doc(id).delete();
  }

  void _toggleComplete(String id, bool current) {
    todos.doc(id).update({'completed': !current});
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'İkon seç'),
              value: _selectedIcon,
              items: _iconOptions.map((icon) {
                return DropdownMenuItem<String>(
                  value: icon['label'],
                  child: Text('${icon['emoji']} ${icon['label']}'),
                );
              }).toList(),

              onChanged: (value) => setState(() => _selectedIcon = value),
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(labelText: 'Alt Başlık'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedDate == null
                    ? 'Tarih seçilmedi'
                    : DateFormat.yMMMMd('tr_TR').format(_selectedDate!)),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      locale: const Locale('tr', 'TR'),
                    );
                    if (pickedDate != null)
                      setState(() => _selectedDate = pickedDate);
                  },
                  child: const Text('Tarih Seç'),
                )
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addTodo,
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görev Listesi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: todos.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Bir hata oluştu'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final iconLabel = data['icon'] ?? '';
              final iconData = _iconOptions.firstWhere(
                  (e) => e['label'] == iconLabel,
                  orElse: () => {'emoji': ''});
              final emoji = iconData['emoji'];
              final title = data['title'] ?? '';
              final subtitle = data['subtitle'] ?? '';
              final timestamp = data['timestamp'];
              final isCompleted = data['completed'] ?? false;

              String dateStr = 'Tarih yok';
              if (timestamp is Timestamp) {
                dateStr = DateFormat.yMMMMd('tr_TR').format(timestamp.toDate());
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$emoji\n${iconLabel}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            Text(subtitle),
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Checkbox(
                            value: isCompleted,
                            onChanged: (_) =>
                                _toggleComplete(docs[index].id, isCompleted),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTodo(docs[index].id),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddModal,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
