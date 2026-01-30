import 'package:equip_sight/components/title_app_design.dart';
import 'package:flutter/material.dart';

// FR: Page d'aide
// RU: Страница помощи
class HelpPage extends StatelessWidget {
  static const String id = 'HelpPage';

  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TitleAppDesign(textTitle: 'ПОМOЩЬ'),
        backgroundColor: Color(0xFF459380),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Как использовать приложение',
              icon: Icons.play_circle_fill,
              color: Colors.blue,
              children: [
                _buildStep(
                  number: 1,
                  title: 'Просмотр состояния машин',
                  description:
                      'Главная страница показывает все машины '
                      'и их статус (свободна, занята, завершена)',
                ),
                _buildStep(
                  number: 2,
                  title: 'Запуск машины',
                  description:
                      'Нажмите на свободную машину, чтобы начать '
                      'цикл на 5 минут',
                ),
                _buildStep(
                  number: 3,
                  title: 'Отслеживание оставшегося времени',
                  description:
                      'Когда машина занята, вы можете '
                      'видеть оставшееся время в минутах',
                ),
                _buildStep(
                  number: 4,
                  title: 'Освободить машину',
                  description:
                      'Когда машина отмечена как "завершена", '
                      'нажмите на неё, чтобы освободить',
                ),
              ],
            ),

            SizedBox(height: 24),

            _buildSection(
              title: 'Уведомления',
              icon: Icons.notifications,
              color: Colors.orange,
              children: [
                _buildInfoItem(
                  icon: Icons.timer,
                  text:
                      'Вы получите уведомление, когда ваша машина '
                      'завершит цикл',
                ),
                _buildInfoItem(
                  icon: Icons.settings,
                  text:
                      'Вы можете включить/отключить уведомления '
                      'в настройках',
                ),
              ],
            ),

            SizedBox(height: 24),

            _buildSection(
              title: 'Решение проблем',
              icon: Icons.warning,
              color: Colors.red,
              children: [
                _buildFAQItem(
                  question: 'Машина не запускается',
                  answer:
                      'Проверьте подключение к интернету и попробуйте снова. '
                      'Если проблема не решена, перезапустите приложение.',
                ),
                _buildFAQItem(
                  question: 'Время не обновляется',
                  answer:
                      'Таймер продолжает работать, даже если приложение закрыто. '
                      'Обновите страницу, чтобы увидеть текущее время.',
                ),
                _buildFAQItem(
                  question: 'Я не получаю уведомления',
                  answer:
                      'Проверьте настройки уведомлений на вашем телефоне '
                      'и убедитесь, что они включены для приложения.',
                ),
                _buildFAQItem(
                  question: 'Машина остаётся "занятой"',
                  answer:
                      'Подождите несколько минут или свяжитесь с '
                      'администратором для сброса машины.',
                ),
              ],
            ),

            SizedBox(height: 24),

            _buildSection(
              title: 'Техническая информация',
              icon: Icons.phone_android,
              color: Colors.green,
              children: [
                _buildTechItem(
                  icon: Icons.security,
                  text: 'Безопасность',
                  description:
                      'Ваше соединение защищено Firebase Authentication. '
                      'Ваши данные находятся под защитой.',
                ),
                _buildTechItem(
                  icon: Icons.cloud,
                  text: 'Синхронизация',
                  description:
                      'Данные синхронизируются в реальном времени '
                      'между всеми пользователями.',
                ),
                _buildTechItem(
                  icon: Icons.timer,
                  text: 'Постоянные таймеры',
                  description:
                      'Таймеры продолжают работу даже после закрытия '
                      'приложения. Они сохраняются локально.',
                ),
              ],
            ),

            SizedBox(height: 24),

            _buildSection(
              title: 'Контакты и поддержка',
              icon: Icons.contact_support,
              color: Color(0xFF459380),
              children: [
                ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text('Email поддержки'),
                  subtitle: Text('equipsight@gmail.com'),
                  onTap: () {
                    // TODO: Реализовать открытие почтового клиента
                  },
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.green),
                  title: Text('Телефон/WhatsApp'),
                  subtitle: Text('+7 991 946 71 88'),
                  onTap: () {
                    // TODO: Реализовать звонок
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bug_report, color: Colors.red),
                  title: Text('Сообщить о баге'),
                  subtitle: Text('Нажмите, чтобы отправить отчет'),
                  onTap: () {
                    _showBugReportDialog(context);
                  },
                ),
              ],
            ),

            SizedBox(height: 32),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Важная информация',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Это приложение находится в разработке. '
                    'Некоторые функции могут изменяться. '
                    'Спасибо за понимание.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.red, width: 3)),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '❓ $question',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              answer,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechItem({
    required IconData icon,
    required String text,
    required String description,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(description),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сообщить о проблеме'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Опишите проблему, с которой вы столкнулись:'),
            SizedBox(height: 12),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Пример: Машина X не запускается...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Реализовать отправку отчета
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Отчет отправлен! Спасибо.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
