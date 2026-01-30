import 'package:equip_sight/model/preferences_model.dart';
import 'package:equip_sight/providers/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  static const String id = 'Settings';

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки уведомлений')),
      body: Consumer<PreferencesProvider>(
        builder: (context, preferencesProvider, child) {
          final prefs = preferencesProvider.preferences;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildSectionHeader('🔔 Типы уведомлений'),
              _buildNotificationSwitch(
                'Завершение стирки',
                'Оповещения, когда стирка завершена',
                prefs.machineFinished,
                (value) => _updatePreference(
                  context,
                  prefs.copyWith(machineFinished: value),
                ),
              ),
              _buildNotificationSwitch(
                'Свободные машины',
                'Оповещения, когда машина освободилась',
                prefs.machineAvailable,
                (value) => _updatePreference(
                  context,
                  prefs.copyWith(machineAvailable: value),
                ),
              ),
              _buildNotificationSwitch(
                'Автонапоминания',
                'Напоминания об освобождении машин',
                prefs.reminders,
                (value) => _updatePreference(
                  context,
                  prefs.copyWith(reminders: value),
                ),
              ),

              SizedBox(height: 24),
              _buildSectionHeader('🎛️ Настройки'),
              _buildNotificationSwitch(
                'Включить звук',
                'Звуковое сопровождение уведомлений',
                prefs.soundEnabled,
                (value) => _updatePreference(
                  context,
                  prefs.copyWith(soundEnabled: value),
                ),
              ),
              _buildNotificationSwitch(
                'Включить вибрацию',
                'Вибрация для уведомлений',
                prefs.vibrationEnabled,
                (value) => _updatePreference(
                  context,
                  prefs.copyWith(vibrationEnabled: value),
                ),
              ),

              SizedBox(height: 24),
              _buildSectionHeader('🏠 Избранные помещения'),
              _buildFavoriteRoomsSection(context, prefs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(Icons.notifications),
    );
  }

  Widget _buildFavoriteRoomsSection(
    BuildContext context,
    NotificationPreferences prefs,
  ) {
    final rooms = [
      'Первый этаж',
      'Второй этаж',
      'Третий этаж',
      'Четвертый этаж',
      'Подвал',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Получать уведомления только для:',
          style: TextStyle(color: Colors.grey[600]),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rooms.map((room) {
            final isSelected = prefs.favoriteRooms.contains(room);
            return FilterChip(
              label: Text(room),
              selected: isSelected,
              onSelected: (selected) {
                final newRooms = List<String>.from(prefs.favoriteRooms);
                if (selected) {
                  newRooms.add(room);
                } else {
                  newRooms.remove(room);
                }
                _updatePreference(
                  context,
                  prefs.copyWith(favoriteRooms: newRooms),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _updatePreference(
    BuildContext context,
    NotificationPreferences newPrefs,
  ) {
    context.read<PreferencesProvider>().updatePreference(newPrefs);
  }
}
