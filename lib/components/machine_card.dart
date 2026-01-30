import 'dart:async';

import 'package:equip_sight/model/model.dart';
import 'package:equip_sight/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MachineCard extends StatefulWidget {
  final Machine machine;
  final Function(Machine)? onActionPressed;
  const MachineCard({super.key, required this.machine, this.onActionPressed});
  @override
  State<MachineCard> createState() => _MachineCardState();
}

class _MachineCardState extends State<MachineCard> {
  Timer? _timer;
  int _remainingSeconds = 0;

  Timer? _reservationTimer;
  int _reservationRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initTimer();
    _initReservationTimer();
  }

  @override
  void didUpdateWidget(covariant MachineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machine.endTime != widget.machine.endTime) {
      _initTimer();
    }

    if (oldWidget.machine.reservationEndTime !=
        widget.machine.reservationEndTime) {
      _initReservationTimer();
    }
  }

  void _initTimer() {
    _timer?.cancel();
    final start = widget.machine.startTime?.toDate();
    final end = widget.machine.endTime?.toDate();
    if (start == null ||
        end == null ||
        widget.machine.statut != MachineStatus.occupe) {
      setState(() => _remainingSeconds = 0);
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now().toUtc();
      final remaining = end.difference(now).inSeconds;
      setState(() {
        _remainingSeconds = remaining > 0 ? remaining : 0;
      });
      if (remaining <= 0) {
        _timer?.cancel();
      }
    });
  }

  void _initReservationTimer() {
    _reservationTimer?.cancel();

    if (widget.machine.statut != MachineStatus.reservee ||
        widget.machine.reservationEndTime == null) {
      setState(() => _reservationRemainingSeconds = 0);
      return;
    }

    final end = widget.machine.reservationEndTime!.toDate();

    _reservationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final remaining = end.difference(DateTime.now()).inSeconds;

      setState(() {
        _reservationRemainingSeconds = remaining > 0 ? remaining : 0;
      });

      if (remaining <= 0) {
        _reservationTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reservationTimer?.cancel();
    super.dispose();
  }

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
                          widget.machine.nom,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          widget.machine.emplacement,
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
    switch (widget.machine.statut) {
      case MachineStatus.libre:
        backgroundColor = Colors.green;
        break;
      case MachineStatus.reservee:
        backgroundColor = Colors.blue;
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
        '${widget.machine.emojiStatut} ${widget.machine.texteStatut}',
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
        final isCurrentUser =
            widget.machine.utilisateurActuel == currentUser?.email;
        final widgets = <Widget>[];
        if (widget.machine.statut == MachineStatus.reservee &&
            widget.machine.reservationEndTime != null) {
          final remaining = _reservationRemainingSeconds;

          widgets.add(
            Text(
              '⏳ Réservation: ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.orange),
            ),
          );
        }
        if (widget.machine.statut == MachineStatus.reservee) {
          widgets.add(
            Text(
              'Réservé par: ${widget.machine.reservedBy}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
        if (widget.machine.statut == MachineStatus.occupe &&
            widget.machine.endTime != null) {
          final minutes = _remainingSeconds ~/ 60;
          final seconds = _remainingSeconds % 60;
          widgets.add(
            Text(
              _remainingSeconds > 0
                  ? '⏱️ $minutes:${seconds.toString().padLeft(2, '0')}'
                  : '⏱️ Завершено',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _remainingSeconds > 0
                    ? Colors.red[700]
                    : Colors.orange[700],
              ),
            ),
          );
        }
        if (widget.machine.utilisateurActuel != null) {
          final userWidgets = <Widget>[
            SizedBox(height: widgets.isNotEmpty ? 8 : 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isCurrentUser ? 'Вы' : widget.machine.utilisateurActuel!,
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
    switch (widget.machine.statut) {
      case MachineStatus.libre:
        buttonText = 'RÉSERVER';
        buttonColor = Colors.blue;
        isEnabled = true;
        break;
      case MachineStatus.reservee:
        final isOwner =
            widget.machine.reservedBy ==
            context.read<UserProvider>().currentUser?.email;
        buttonText = isOwner ? 'DÉMARRER' : 'RÉSERVÉE';
        buttonColor = isOwner ? Colors.green : Colors.grey;
        isEnabled = isOwner;
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
        onPressed: isEnabled
            ? () => widget.onActionPressed?.call(widget.machine)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
        ),
        child: Text(buttonText),
      ),
    );
  }
}
