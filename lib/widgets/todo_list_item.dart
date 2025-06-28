import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoListItem extends StatelessWidget {
  final Map<String, dynamic> todo;
  final Function(bool?) onToggleComplete;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const TodoListItem({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime? dueDate =
        todo['due_date'] != null ? DateTime.tryParse(todo['due_date']) : null;
    final String? dueTimeStr = todo['due_time'];
    TimeOfDay? dueTime;

    if (dueTimeStr != null && dueTimeStr.isNotEmpty) {
      try {
        final parts = dueTimeStr.split(':');
        dueTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        print('Error Parsing time: $e');
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(todo['id'].toString()),
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
          return await _showDeleteConfirmDialog(context);
        },
        onDismissed: (_) => onDismissed(),
        child: Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Checkbox(
                    value: todo['is_complete'],
                    onChanged: onToggleComplete,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      todo['task'],
                      style: TextStyle(
                        fontSize: 16,
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
                  const SizedBox(width: 8),
                  _buildDateTimeInfo(context, dueDate, dueTime),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeInfo(
    BuildContext context,
    DateTime? date,
    TimeOfDay? time,
  ) {
    if (date == null && time == null) return const SizedBox.shrink();

    return Row(
      children: [
        if (date != null) ...[
          Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            DateFormat('yyyy-MM-dd').format(date),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
        if (date != null && time != null) const SizedBox(width: 8),
        if (time != null) ...[
          Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            time.format(context),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Task?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
