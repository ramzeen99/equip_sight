import 'package:provider/provider.dart';
import 'package:laundry_lens/model/model.dart';
import 'package:laundry_lens/providers/user_provider.dart';
import 'package:flutter/material.dart';

// FR : Carte affichant une machine avec ses informations
// RU : Карточка стиральной машины с подробной информацией
class MachineCard extends StatelessWidget {
  final Machine machine;
  final Function(Machine)? onActionPressed;

  const MachineCard({super.key, required this.machine, this.onActionPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 200,
          maxHeight: 300, // FR : Hauteur max — RU : Максимальная высота
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FR : En-tête de la carte
              // RU : Верхняя часть карточки
              Row(
                children: [
                  Icon(
                    Icons.local_laundry_service,
                    size: 32,
                    color: Colors.blue[700],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.nom, // FR : Nom de la machine — RU : Название машины
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          machine.emplacement, // FR : Emplacement — RU : Местоположение
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // FR : Badge de statut
              // RU : Индикатор статуса
              _buildStatusBadge(),

              SizedBox(height: 12),

              // FR : Informations dynamiques selon l'état
              // RU : Динамическая информация в зависимости от статуса
              _buildDynamicContent(context),

              SizedBox(height: 16),

              // FR : Bouton d'action
              // RU : Кнопка действия
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  // FR : Badge de couleur indiquant le statut
  // RU : Цветной индикатор текущего статуса машины
  Widget _buildStatusBadge() {
    Color backgroundColor;

    switch (machine.statut) {
      case MachineStatus.libre:
        backgroundColor = Colors.green;
        break;
      case MachineStatus.occupe:
        backgroundColor = Colors.red;
        break;
      case MachineStatus.termine:
        backgroundColor = Colors.orange;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        // FR : Texte + emoji déjà fournis
        // RU : Текст и эмодзи приходят из модели
        '${machine.emojiStatut} ${machine.texteStatut}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // FR : Zone dynamique : temps restant, utilisateur actuel, photo...
  // RU : Динамическая зона: оставшееся время, текущий пользователь, фото...
  Widget _buildDynamicContent(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final isCurrentUser = machine.utilisateurActuel == currentUser?.email;

        final widgets = <Widget>[];

        // FR : Temps restant si machine occupée
        // RU : Оставшееся время, если машина занята
        if (machine.statut == MachineStatus.occupe &&
            machine.tempsRestant != null) {
          widgets.add(
            Text(
              '⏱️ ${machine.tempsRestant} мин осталось', // FR : min restantes — RU : мин осталось
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red[700],
              ),
            ),
          );
        }

        // FR : Affichage utilisateur actuel
        // RU : Отображение текущего пользователя
        if (machine.utilisateurActuel != null) {
          final userWidgets = <Widget>[
            SizedBox(height: widgets.isNotEmpty ? 8 : 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isCurrentUser ? 'Вы' : machine.utilisateurActuel!,
                    // FR : "Vous" → RU : "Вы"
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: isCurrentUser
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ];

          // FR : Photo de l'utilisateur s'il est connecté
          // RU : Фото пользователя, если он подключён
          if (isCurrentUser && currentUser?.photoURL != null) {
            userWidgets.addAll([
              SizedBox(height: 4),
              Container(
                margin: EdgeInsets.only(top: 4),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(currentUser!.photoURL!),
                ),
              ),
            ]);
          }

          widgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: userWidgets,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        );
      },
    );
  }

  // FR : Bouton d'action selon le statut
  // RU : Кнопка действия в зависимости от статуса машины
  Widget _buildActionButton() {
    String buttonText;
    Color buttonColor;
    bool isEnabled;

    switch (machine.statut) {
      case MachineStatus.libre:
        buttonText = 'НАЧАТЬ'; // FR : DÉMARRER — RU : НАЧАТЬ
        buttonColor = Colors.green;
        isEnabled = true;
        break;
      case MachineStatus.occupe:
        buttonText = 'ЗАНЯТО'; // FR : OCCUPÉ — RU : ЗАНЯТО
        buttonColor = Colors.grey;
        isEnabled = false;
        break;
      case MachineStatus.termine:
        buttonText = 'ОСВОБОДИТЬ'; // FR : LIBÉRER — RU : ОСВОБОДИТЬ
        buttonColor = Colors.orange;
        isEnabled = true;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? () => onActionPressed?.call(machine) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
        child: Text(buttonText),
      ),
    );
  }
}
