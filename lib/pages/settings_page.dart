import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laundry_lens/providers/preferences_provider.dart';
import 'package:laundry_lens/model/preferences_model.dart';

class SettingsPage extends StatelessWidget {
  static const String id = 'Settings';

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Заголовок страницы настроек / Titre de la page des paramètres
      appBar: AppBar(title: Text('Настройки уведомлений')),
      body: Consumer<PreferencesProvider>(
        builder: (context, preferencesProvider, child) {
          final prefs = preferencesProvider.preferences;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Секция типов уведомлений / Section types de notifications
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
              // Секция настроек / Section préférences
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
              // Секция избранных помещений / Section pièces favorites
              _buildSectionHeader('🏠 Избранные помещения'),
              _buildFavoriteRoomsSection(context, prefs),
            ],
          );
        },
      ),
    );
  }

  // Виджет заголовка секции / Widget d'en-tête de section
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

  // Виджет переключателя уведомлений / Widget interrupteur de notification
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

  // Секция избранных помещений / Section pièces favorites
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

  // Метод обновления настроек / Méthode de mise à jour des préférences
  void _updatePreference(
      BuildContext context,
      NotificationPreferences newPrefs,
      ) {
    context.read<PreferencesProvider>().updatePreference(newPrefs);
  }
}