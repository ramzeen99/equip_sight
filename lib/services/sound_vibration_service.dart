import 'package:audioplayers/audioplayers.dart';
import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/model/preferences_model.dart';
import 'package:vibration/vibration.dart';

class SoundVibrationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static const Map<NotificationType, String> _notificationSounds = {
    NotificationType.machineFinished: 'sounds/machine_finished.mp3',
    NotificationType.machineAvailable: 'sounds/machine_available.mp3',
    NotificationType.reminder: 'sounds/reminder.mp3',
    NotificationType.maintenance: 'sounds/maintenance.mp3',
    NotificationType.system: 'sounds/system.mp3',
  };

  static const Map<NotificationType, List<int>> _vibrationPatterns = {
    NotificationType.machineFinished: [500, 1000, 500],
    NotificationType.machineAvailable: [200, 500],
    NotificationType.reminder: [100, 200, 100, 200],
    NotificationType.maintenance: [1000],
    NotificationType.system: [500],
  };

  static Future<void> playNotificationEffects({
    required NotificationType type,
    required NotificationPreferences preferences,
  }) async {
    if (preferences.soundEnabled) {
      await _playSound(type);
    }

    if (preferences.vibrationEnabled) {
      await _playVibration(type);
    }
  }

  static Future<void> _playSound(NotificationType type) async {
    try {
      final soundPath = _notificationSounds[type];
      if (soundPath != null) {
        await _audioPlayer.play(AssetSource(soundPath));
      }
    } catch (e) {
      await _playFallbackSound();
    }
  }

  static Future<void> _playFallbackSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/fallback.mp3'));
    } catch (e) {
      //print('❌ Ошибка резервного звука: $e / Erreur son fallback: $e');
    }
  }

  static Future<void> _playVibration(NotificationType type) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();

      if (hasVibrator) {
        final pattern = _vibrationPatterns[type];

        if (pattern != null) {
          await Vibration.vibrate(pattern: pattern);
        } else {
          await Vibration.vibrate(duration: 500);
        }
      }
    } catch (e) {
      // print('❌ Ошибка вибрации: $e / Erreur vibration: $e');
    }
  }

  static Future<void> stopAllEffects() async {
    await _audioPlayer.stop();
    await Vibration.cancel();
  }

  static Future<void> testSound(NotificationType type) async {
    await _playSound(type);
  }

  static Future<void> testVibration(NotificationType type) async {
    await _playVibration(type);
  }
}
