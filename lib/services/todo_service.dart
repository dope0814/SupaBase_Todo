import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodoService {
  final _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getTodosStream() {
    return _client
        .from('todos')
        .stream(primaryKey: ['id'])
        .eq('is_deleted', false)
        .order('created_at', ascending: true);
  }

  //insert Data
  void addTodo({
    required String task,
    DateTime? dueDate,
    TimeOfDay? dueTime,
  }) async {
    final Map<String, dynamic> insertData = {
      'task': task,
      'is_complete': false,
    };

    if (dueDate != null) {
      insertData['due_date'] = DateFormat('yyy=MM-dd').format(dueDate);
    }
    if (dueTime != null) {
      final hour = dueTime.hour.toString().padLeft(2, '0');
      final minute = dueTime.minute.toString().padLeft(2, '0');
      insertData['due_time'] = '$hour:$minute:00';
    }

    await _client.from('todos').insert(insertData);
  }

  //update Data
  void updateTodo(
    String id, {
    String? task,
    bool? isComplete,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool setDateNull = false,
    bool setTimeNull = false,
  }) async {
    final Map<String, dynamic> updateData = {};

    if (task != null) updateData['task'] = task;
    if (isComplete != null) updateData['is_complete'] = isComplete;

    if (setDateNull) {
      updateData['due_date'] = null;
    } else if (dueDate != null) {
      updateData['due_date'] = DateFormat('yyyy-MM-dd').format(dueDate);
    }

    if (setTimeNull) {
      updateData['due_time'] = null;
    } else if (dueTime != null) {
      final hour = dueTime.hour.toString().padLeft(2, '0');
      final minute = dueTime.minute.toString().padLeft(2, '0');
      updateData['due_time'] = '$hour:$minute:00';
    }

    if (updateData.isNotEmpty) {
      await _client.from('todos').update(updateData).eq('id', id);
    }
  }

  void deleteTodo(String id) async {
    await _client.from('todos').update({'is_deleted': true}).eq('id', id);
  }
}
