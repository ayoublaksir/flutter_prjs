import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/form_widgets.dart';

class MotivationEntryScreen extends StatefulWidget {
  final String challengeId;

  const MotivationEntryScreen({Key? key, required this.challengeId})
    : super(key: key);

  @override
  _MotivationEntryScreenState createState() => _MotivationEntryScreenState();
}

class _MotivationEntryScreenState extends State<MotivationEntryScreen> {
  final _messageController = TextEditingController();
  TimeOfDay _reminderTime = TimeOfDay(hour: 9, minute: 0);
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri by default
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set Motivation Reminder')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When do you want to receive reminders?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            _buildDaySelector(),
            SizedBox(height: 16),
            _buildTimeSelector(),
            SizedBox(height: 24),
            CustomTextField(
              label: 'Motivation Message',
              controller: _messageController,
              validator:
                  (value) =>
                      value?.isEmpty ?? true ? 'Please enter a message' : null,
            ),
            SizedBox(height: 24),
            CustomButton(
              text: 'Save Reminder',
              onPressed: _handleSaveReminder,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index);
              } else {
                _selectedDays.remove(index);
              }
            });
          },
        );
      }),
    );
  }

  Widget _buildTimeSelector() {
    return ListTile(
      title: Text('Reminder Time'),
      trailing: Text(_reminderTime.format(context)),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _reminderTime,
        );
        if (time != null) {
          setState(() => _reminderTime = time);
        }
      },
    );
  }

  Future<void> _handleSaveReminder() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a motivation message')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final reminder = ReminderModel(
        id: '',
        challengeId: widget.challengeId,
        time: _reminderTime,
        message: _messageController.text,
        activeDays: _selectedDays,
      );

      await context.read<DatabaseService>().createReminder(reminder);

      // Schedule the notification
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _reminderTime.hour,
        _reminderTime.minute,
      );

      await context.read<NotificationService>().scheduleReminder(
        'Challenge Reminder',
        _messageController.text,
        scheduledTime,
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
