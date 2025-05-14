//https://docs.google.com/document/d/1Jl-sqqMtQYfy7Su_O6yxnstmFlKO-4k5ldyDOmJfa_0/edit?usp=sharing

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _taskController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _addTask() async {
    final String task = _taskController.text.trim();

    if (task.isNotEmpty) {
      await _db.collection("tasks").add({
        "task": task,
        "isDone": false,
        "createdAt": Timestamp.now(),
      });

      _taskController.clear();
    }
  }

  void _toggleTask(DocumentSnapshot doc) async {
    await _db.collection("tasks").doc(doc.id).update({
      "isDone": !(doc['isDone'] as bool),
    });
  }

  void _deleteTask(DocumentSnapshot doc) async {
    await _db.collection("tasks").doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(labelText: 'Enter Task'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTask,
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 24),
            const Expanded(child: TaskList()),
          ],
        ),
      ),
    );
  }
}

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection("tasks").orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final task = data['task'] ?? '';
            final isDone = data['isDone'] ?? false;

            return ListTile(
              title: Text(
                task,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              leading: Checkbox(
                value: isDone,
                onChanged: (_) {
                  _db.collection("tasks").doc(doc.id).update({
                    "isDone": !isDone,
                  });
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _db.collection("tasks").doc(doc.id).delete();
                },
              ),
            );
          },
        );
      },
    );
  }
}