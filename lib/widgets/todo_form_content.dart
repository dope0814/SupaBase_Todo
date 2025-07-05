import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodoFormContent extends StatefulWidget {
  // 수정할 때 초기 데이터를 받기 위한 변수
  final Map<String, dynamic>? initialTodo;
  // 저장 버튼을 눌렀을 때 실행될 콜백 함수
  final Function({
    required String task,
    DateTime? date,
    TimeOfDay? time,
    required bool isDateCleared,
    required bool isTimeCleared,
  })
  onSave;

  const TodoFormContent({super.key, this.initialTodo, required this.onSave});

  @override
  State<TodoFormContent> createState() => _TodoFormContentState();
}

class _TodoFormContentState extends State<TodoFormContent> {
  late final TextEditingController _taskController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isDateCleared = false;
  bool _isTimeCleared = false;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.initialTodo?['task']);

    final todo = widget.initialTodo;
    if (todo != null) {
      if (todo['due_date'] != null) {
        _selectedDate = DateTime.tryParse(todo['due_date']);
      }
      final String? dueTimeStr = todo['due_time'];
      if (dueTimeStr != null && dueTimeStr.isNotEmpty) {
        try {
          final parts = dueTimeStr.split(':');
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (e) {
          // print('Error parsing time for edit: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialTodo != null;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditMode ? 'Edit Task' : 'New Task',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _taskController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildDateTimePicker(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  widget.onSave(
                    task: _taskController.text,
                    date: _selectedDate,
                    time: _selectedTime,
                    isDateCleared: _isDateCleared,
                    isTimeCleared: _isTimeCleared,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditMode ? 'Save Changes' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  // 날짜와 시간을 선택하는 UI 부분을 별도 메서드로 추출
  Widget _buildDateTimePicker() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today),
          title: Text(
            _selectedDate == null
                ? 'Select Date (Optional)'
                : DateFormat('yyyy-MM-dd').format(_selectedDate!),
          ),
          trailing:
              _selectedDate != null
                  ? IconButton(
                    onPressed:
                        () => setState(() {
                          _selectedDate = null;
                          _isDateCleared = true; // 날짜가 지워졌음을 표시
                        }),
                    icon: const Icon(Icons.clear),
                  )
                  : null,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
                _isDateCleared = false; // 날짜가 선택되었으므로 지움 표시 해제
              });
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.access_time),
          title: Text(
            _selectedTime == null
                ? 'Select Time (Optional)'
                : _selectedTime!.format(context),
          ),
          trailing:
              _selectedTime != null
                  ? IconButton(
                    onPressed:
                        () => setState(() {
                          _selectedTime = null;
                          _isTimeCleared = true; // 시간이 지워졌음을 표시
                        }),
                    icon: const Icon(Icons.clear),
                  )
                  : null,
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime ?? TimeOfDay.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedTime = picked;
                _isTimeCleared = false; // 시간이 선택되었으므로 지움 표시 해제
              });
            }
          },
        ),
      ],
    );
  }
}
