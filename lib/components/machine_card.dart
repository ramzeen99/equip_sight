import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        constraints: BoxConstraints(minHeight: 200, maxHeight: 300),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          machine.nom,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          machine.emplacement,
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

              _buildStatusBadge(),

              SizedBox(height: 12),

              _buildDynamicContent(context),

              SizedBox(height: 16),

              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

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
        '${machine.emojiStatut} ${machine.texteStatut}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDynamicContent(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.currentUser;
        final isCurrentUser = machine.utilisateurActuel == currentUser?.email;

        final widgets = <Widget>[];

        if (machine.statut == MachineStatus.occupe && machine.endTime != null) {
          final remainingSeconds = machine.endTime!
              .toDate()
              .difference(DateTime.now())
              .inSeconds;

          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;

          if (remainingSeconds > 0) {
            widgets.add(
              Text(
                '⏱️ $minutes:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
              ),
            );
          } else {
            widgets.add(
              Text(
                '⏱️ Завершено',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[700],
                ),
              ),
            );
          }
        }

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

  Widget _buildActionButton() {
    String buttonText;
    Color buttonColor;
    bool isEnabled;

    switch (machine.statut) {
      case MachineStatus.libre:
        buttonText = 'НАЧАТЬ';
        buttonColor = Colors.green;
        isEnabled = true;
        break;
      case MachineStatus.occupe:
        buttonText = 'ЗАНЯТО';
        buttonColor = Colors.grey;
        isEnabled = false;
        break;
      case MachineStatus.termine:
        buttonText = 'ОСВОБОДИТЬ';
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
