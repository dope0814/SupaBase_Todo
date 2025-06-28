import 'package:flutter/material.dart';
import 'package:todo_app/services/todo_service.dart';
import 'package:todo_app/widgets/todo_form_content.dart';
import 'package:todo_app/widgets/todo_list_item.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _todoService = TodoService();
  late final Stream<List<Map<String, dynamic>>> _todoStream;

  @override
  void initState() {
    super.initState();
    _todoStream = _todoService.getTodosStream();
  }

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
            return Center(child: Text('Eroor: ${snapshot.error}'));
          }
          final todos = snapshot.data ?? [];
          if (todos.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todos.length,
            itemBuilder: (context, i) {
              final todo = todos[i];

              return TodoListItem(
                todo: todo,
                onTap: () => _showFormDialog(context, todo: todo),
                onToggleComplete: (isComplete) {
                  _todoService.updateTodo(todo['id'], isComplete: isComplete);
                },
                onDismissed: () {
                  _todoService.deleteTodo(todo['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${todo['task']} deleted.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'All Clear! Add a new Task.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, {Map<String, dynamic>? todo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return TodoFormContent(
          initialTodo: todo,
          onSave: ({
            required task,
            date,
            time,
            required isDateCleared,
            required isTimeCleared,
          }) {
            if (todo == null) {
              _todoService.addTodo(task: task, dueDate: date, dueTime: time);
            } else {
              _todoService.updateTodo(
                todo['id'],
                task: task,
                dueDate: date,
                dueTime: time,
                setDateNull: isDateCleared,
                setTimeNull: isTimeCleared,
              );
            }
          },
        );
      },
    );
  }
}
