import 'package:audioplayers/audioplayers.dart';
import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/model/preferences_model.dart';
import 'package:vibration/vibration.dart';

class SoundVibrationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // 🎵 Звуки для различных типов уведомлений / Sons pour différents types de notifications
  static const Map<NotificationType, String> _notificationSounds = {
    NotificationType.machineFinished: 'sounds/machine_finished.mp3',
    NotificationType.machineAvailable: 'sounds/machine_available.mp3',
    NotificationType.reminder: 'sounds/reminder.mp3',
    NotificationType.maintenance: 'sounds/maintenance.mp3',
    NotificationType.system: 'sounds/system.mp3',
  };

  // 📳 Паттерны вибрации / Patterns de vibration
  static const Map<NotificationType, List<int>> _vibrationPatterns = {
    NotificationType.machineFinished: [500, 1000, 500], // 🎉 Длинный / Long
    NotificationType.machineAvailable: [200, 500], // ✅ Средний / Moyen
    NotificationType.reminder: [
      100,
      200,
      100,
      200,
    ], // ⏰ Короткий повторяющийся / Court répété
    NotificationType.maintenance: [1000], // 🚧 Длинный одиночный / Long unique
    NotificationType.system: [500], // ℹ️ Средний одиночный / Moyen unique
  };

  // 🎯 Воспроизвести эффекты для уведомления / Jouer les effets pour une notification
  static Future<void> playNotificationEffects({
    required NotificationType type,
    required NotificationPreferences preferences,
  }) async {
    // 🎵 Воспроизвести звук, если включен / Jouer le son si activé
    if (preferences.soundEnabled) {
      await _playSound(type);
    }

    // 📳 Воспроизвести вибрацию, если включена / Jouer la vibration si activée
    if (preferences.vibrationEnabled) {
      await _playVibration(type);
    }
  }

  // 🎵 Воспроизвести звук / Jouer un son
  static Future<void> _playSound(NotificationType type) async {
    try {
      final soundPath = _notificationSounds[type];
      if (soundPath != null) {
        await _audioPlayer.play(AssetSource(soundPath));
        //print('🔊 Звук воспроизведен: $soundPath / Son joué: $soundPath');
      }
    } catch (e) {
      //  print('❌ Ошибка звука: $e / Erreur son: $e');
      // 🎵 Резервный звук / Son de fallback
      await _playFallbackSound();
    }
  }

  // 🎵 Резервный звук (простой сигнал) / Son de fallback (bip simple)
  static Future<void> _playFallbackSound() async {
    try {
      // Воспроизвести системный сигнал / Jouer un bip système
      await _audioPlayer.play(AssetSource('sounds/fallback.mp3'));
    } catch (e) {
      //print('❌ Ошибка резервного звука: $e / Erreur son fallback: $e');
    }
  }

  // 📳 Воспроизвести вибрацию / Jouer une vibration
  static Future<void> _playVibration(NotificationType type) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();

      if (hasVibrator) {
        final pattern = _vibrationPatterns[type];

        if (pattern != null) {
          await Vibration.vibrate(pattern: pattern);
          //print('📳 Вибрация воспроизведена: $pattern / Vibration jouée: $pattern');
        } else {
          // 📳 Вибрация по умолчанию / Vibration par défaut
          await Vibration.vibrate(duration: 500);
        }
      }
    } catch (e) {
      // print('❌ Ошибка вибрации: $e / Erreur vibration: $e');
    }
  }

  // ⏹️ Остановить все эффекты / Arrêter tous les effets
  static Future<void> stopAllEffects() async {
    await _audioPlayer.stop();
    await Vibration.cancel();
  }

  // 🔊 Тестировать звуки / Tester les sons
  static Future<void> testSound(NotificationType type) async {
    await _playSound(type);
  }

  // 📳 Тестировать вибрации / Tester les vibrations
  static Future<void> testVibration(NotificationType type) async {
    await _playVibration(type);
  }
}
