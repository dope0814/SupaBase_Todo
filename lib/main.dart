import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://aqfhjfggihdrxqliovhj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxZmhqZmdnaWhkcnhxbGlvdmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA0MDQ1MDQsImV4cCI6MjA2NTk4MDUwNH0.IeXuQJUTVEONKn6STPYWAFLXOI0Z28Z85QqgU_gLFZ0',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: AppTheme.notionLikeThmem,
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _todoStream = Supabase.instance.client
      .from('todos')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: StreamBuilder(
        stream: _todoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            );
          }
          if (snapshot.hasError) {
            print('StreamBuilder Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 80,
                    color: Colors.blueGrey.shade200,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All clear! Add a new task.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final todos = snapshot.data as List;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              final DateTime? dueDate =
                  todo['due_date'] != null
                      ? DateTime.tryParse(todo['due_date'])
                      : null;
              final String? dueTimeStr = todo['due_time'];
              TimeOfDay? dueTime;

              if (dueTimeStr != null && dueTimeStr.isNotEmpty) {
                try {
                  final parts = dueTimeStr.split(':');
                  final hour = int.parse(parts[0]);
                  final minute = int.parse(parts[1]);
                  dueTime = TimeOfDay(hour: hour, minute: minute);
                } catch (e) {
                  print('Error Parsing time : $e');
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: Key(todo['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text(
                            'Delete Task?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          content: const Text(
                            "Are you sure you want to delete this task?",
                            style: TextStyle(color: Colors.black87),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) async {
                    await Supabase.instance.client
                        .from('todos')
                        .delete()
                        .eq('id', todo['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${todo['task']} deleted.',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.blueGrey.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    child: InkWell(
                      onTap: () {
                        _editTask(context, todo);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: todo['is_complete'],
                              onChanged: (bool? v) async {
                                await Supabase.instance.client
                                    .from('todos')
                                    .update({'is_complete': v})
                                    .eq('id', todo['id']);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                todo['task'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                  decoration:
                                      todo['is_complete']
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                  color:
                                      todo['is_complete']
                                          ? Colors.grey[500]
                                          : Colors.black87,
                                ),
                              ),
                            ),
                            if (dueDate != null || dueTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    if (dueDate != null)
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                    if (dueDate != null)
                                      const SizedBox(width: 4),
                                    if (dueDate != null)
                                      Text(
                                        DateFormat('MM/dd').format(dueDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    if (dueDate != null && dueTime != null)
                                      const SizedBox(width: 8),
                                    if (dueTime != null)
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                    if (dueTime != null)
                                      const SizedBox(width: 4),
                                    if (dueTime != null)
                                      Text(
                                        dueTime.format(context),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              // return
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTodoItem(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editTask(BuildContext context, Map<String, dynamic> todo) {
    final TextEditingController taskController = TextEditingController(
      text: todo['task'],
    );
    DateTime? selectedDate =
        todo['due_date'] != null ? DateTime.tryParse(todo['due_date']) : null;
    TimeOfDay? selectedTime;

    final String? dueTimeStr = todo['due_time'];
    if (dueTimeStr != null && dueTimeStr.isNotEmpty) {
      try {
        final parts = dueTimeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        selectedTime = TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        print('Error parsing time for edit: $e');
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Edit Task',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Task Description',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDate == null
                            ? 'Select Date (Optional)'
                            : DateFormat('yyyy-MM-dd').format(selectedDate!),
                      ),
                      trailing:
                          selectedDate != null
                              ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDate = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              )
                              : null,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        selectedTime == null
                            ? ';Select Time (Optional)'
                            : selectedTime!.format(context),
                      ),
                      trailing:
                          selectedTime != null
                              ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedTime = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              )
                              : null,
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null && picked != selectedTime) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (taskController.text.isNotEmpty) {
                      final Map<String, dynamic> updateData = {
                        'task': taskController.text,
                      };

                      if (selectedDate != null) {
                        updateData['due_date'] = DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDate!);
                      } else {
                        updateData['due_date'] = null;
                      }

                      if (selectedTime != null) {
                        final String hour = selectedTime!.hour
                            .toString()
                            .padLeft(2, '0');
                        final String minute = selectedTime!.minute
                            .toString()
                            .padLeft(2, '0');
                        updateData['due_time'] = '$hour:$minute:00';
                      } else {
                        updateData['due_time'] = null;
                      }

                      await Supabase.instance.client
                          .from('todos')
                          .update(updateData)
                          .eq('id', todo['id']);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addTodoItem(BuildContext context) {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'New Task',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Task Description',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDate == null
                            ? 'Selected Date (Optional)'
                            : DateFormat('yyyy-MM-dd').format(selectedDate!),
                      ),
                      trailing:
                          selectedDate != null
                              ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedDate = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              )
                              : null,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        selectedTime == null
                            ? 'Select Time (Optional)'
                            : selectedTime!.format(context),
                      ),
                      trailing:
                          selectedTime != null
                              ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedTime = null;
                                  });
                                },
                                icon: Icon(Icons.clear),
                              )
                              : null,
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null && picked != selectedTime) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (taskController.text.isNotEmpty) {
                      final Map<String, dynamic> insertData = {
                        'task': taskController.text,
                        'is_complete': false,
                      };

                      if (selectedDate != null) {
                        insertData['due_date'] = DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDate!);
                      }
                      if (selectedTime != null) {
                        final String hour = selectedTime!.hour
                            .toString()
                            .padLeft(2, '0');
                        final String minute = selectedTime!.minute
                            .toString()
                            .padLeft(2, '0');
                        insertData['due_time'] = '$hour:$minute:00';
                      }

                      await Supabase.instance.client
                          .from('todos')
                          .insert(insertData);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
