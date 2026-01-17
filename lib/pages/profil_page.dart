import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laundry_lens/providers/user_provider.dart';
import 'package:laundry_lens/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  static const String id = 'Profile';

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мой профиль'),
        backgroundColor: Color(0xFF459380),
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final user = userProvider.currentUser;

          if (user == null) {
            return _buildNotConnected();
          }

          return _buildProfileContent(context, user, userProvider);
        },
      ),
    );
  }

  Widget _buildNotConnected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Не авторизован',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Войдите, чтобы получить доступ к профилю',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context,
      AppUser user,
      UserProvider userProvider,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: user.hasPhoto ? NetworkImage(user.photoURL!) : null,
            backgroundColor: Colors.blueGrey[300],
            child: user.hasPhoto
                ? null
                : Icon(Icons.person, size: 60, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            user.displayNameOrEmail,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            user.email,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (user.emailVerified == true) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Почта подтверждена',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
              ],
            ),
          ],
          SizedBox(height: 20),

          // 🌍 Localisation & dortoir affichage
          _buildBadge(Icons.flag, "Pays", user.pays ?? "Non défini"),
          _buildBadge(Icons.location_city, "Ville", user.ville ?? "Non défini"),
          _buildBadge(Icons.school, "Université", user.universite ?? "Non défini"),
          _buildBadge(Icons.apartment, "Dortoir", user.dortoir ?? "Non défini"),

          SizedBox(height: 32),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Изменить имя'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showEditNameDialog(context, userProvider),
                ),
                ListTile(
                  leading: Icon(Icons.public, color: Colors.teal),
                  title: Text('Changer localisation / dortoir'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showEditLocationDialog(context, user, userProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          SizedBox(width: 8),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, UserProvider userProvider) {
    final controller = TextEditingController(text: userProvider.currentUser?.displayName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Modifier имя'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Nom d'affichage",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              await userProvider.updateProfile(displayName: newName);
              Navigator.pop(context);
            },
            child: Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }

  // 🏫 Modifier localisation & dortoir
  void _showEditLocationDialog(
      BuildContext context,
      AppUser user,
      UserProvider userProvider,
      ) async {
    final firestore = FirebaseFirestore.instance;

    String? newCountry = user.pays;
    String? newCity = user.ville;
    String? newUniversity = user.universite;
    String? newDorm = user.dortoir;

    List<String> countryList = (await firestore.collection('countries').get()).docs.map((e) => e.id).toList();
    List<String> cityList = [];
    List<String> uniList = [];
    List<String> dormList = [];

    if (newCountry != null) {
      cityList = (await firestore.collection('countries').doc(newCountry).collection('cities').get())
          .docs.map((e) => e.id).toList();
    }

    if (newCountry != null && newCity != null) {
      uniList = (await firestore.collection('countries').doc(newCountry).collection('cities').doc(newCity)
          .collection('universities').get())
          .docs.map((e) => e.id).toList();
    }

    if (newCountry != null && newCity != null && newUniversity != null) {
      dormList = (await firestore.collection('countries').doc(newCountry).collection('cities').doc(newCity)
          .collection('universities').doc(newUniversity).collection('dorms').get())
          .docs.map((e) => e.id).toList();
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Modifier dortoir & localisation"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField(
                  initialValue: newCountry,
                  items: countryList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) async {
                    setStateDialog(() {
                      newCountry = v;
                      newCity = null;
                      newUniversity = null;
                      newDorm = null;
                      cityList = [];
                      uniList = [];
                      dormList = [];
                    });

                    cityList = (await firestore.collection('countries').doc(v).collection('cities').get())
                        .docs.map((e) => e.id).toList();
                    setStateDialog(() {});
                  },
                  decoration: InputDecoration(labelText: "Pays"),
                ),
                DropdownButtonFormField(
                  initialValue: newCity,
                  items: cityList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) async {
                    setStateDialog(() {
                      newCity = v;
                      newUniversity = null;
                      newDorm = null;
                      uniList = [];
                      dormList = [];
                    });

                    uniList = (await firestore.collection('countries').doc(newCountry)
                        .collection('cities').doc(v).collection('universities').get())
                        .docs.map((e) => e.id).toList();
                    setStateDialog(() {});
                  },
                  decoration: InputDecoration(labelText: "Ville"),
                ),
                DropdownButtonFormField(
                  initialValue: newUniversity,
                  items: uniList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) async {
                    setStateDialog(() {
                      newUniversity = v;
                      newDorm = null;
                      dormList = [];
                    });

                    dormList = (await firestore.collection('countries').doc(newCountry)
                        .collection('cities').doc(newCity)
                        .collection('universities').doc(v).collection('dorms').get())
                        .docs.map((e) => e.id).toList();
                    setStateDialog(() {});
                  },
                  decoration: InputDecoration(labelText: "Université"),
                ),
                DropdownButtonFormField(
                  initialValue: newDorm,
                  items: dormList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setStateDialog(() => newDorm = v),
                  decoration: InputDecoration(labelText: "Dortoir"),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
              ElevatedButton(
                onPressed: () async {
                  if (newDorm == null) return;

                  await firestore.collection('users').doc(user.id).update({
                    'pays': newCountry,
                    'ville': newCity,
                    'universite': newUniversity,
                    'dortoir': newDorm,
                    'lastUpdate': FieldValue.serverTimestamp(),
                  });

                  await userProvider.waitForInitialization();
                  Navigator.pop(context);
                },
                child: Text("Sauvegarder"),
              ),
            ],
          );
        });
      },
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:laundry_lens/providers/user_provider.dart';
import 'package:laundry_lens/model/user_model.dart';

class ProfilePage extends StatelessWidget {
  static const String id = 'Profile';

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мой профиль'), // Мой профиль
        backgroundColor: Color(0xFF459380),
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final user = userProvider.currentUser;

          if (user == null) {
            return _buildNotConnected();
          }

          return _buildProfileContent(context, user, userProvider);
        },
      ),
    );
  }

  Widget _buildNotConnected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Не авторизован', // Не подключен
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Войдите, чтобы получить доступ к профилю', // Подключитесь для доступа к вашему профилю
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context,
      AppUser user,
      UserProvider userProvider,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 🖼️ Фото профиля / Photo de profil
          CircleAvatar(
            radius: 60,
            backgroundImage: user.hasPhoto
                ? NetworkImage(user.photoURL!)
                : null,
            backgroundColor: Colors.blueGrey[300],
            child: user.hasPhoto
                ? null
                : Icon(Icons.person, size: 60, color: Colors.white),
          ),

          SizedBox(height: 16),

          // 👤 Имя / Nom
          Text(
            user.displayNameOrEmail,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 8),

          // 📧 Электронная почта / Email
          Text(
            user.email,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),

          // ✅ Значок подтвержденной почты / Badge email vérifié
          if (user.emailVerified == true) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Почта подтверждена', // Email vérifié
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
              ],
            ),
          ],

          SizedBox(height: 32),

          // 🎯 Быстрые действия / Actions rapides
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Изменить имя'), // Modifier mon nom
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showEditNameDialog(context, user, userProvider),
                ),
                ListTile(
                  leading: Icon(Icons.history, color: Colors.orange),
                  title: Text('Моя история'), // Mon historique
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigator.pushNamed(context, HistoryPage.id);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.grey),
                  title: Text('Настройки'), // Paramètres
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigator.pushNamed(context, SettingsPage.id);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // ℹ️ Информация об аккаунте / Informations compte
          Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Информация об аккаунте', // Informations du compte
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  _buildInfoItem('ID пользователя', user.id), // ID utilisateur
                  _buildInfoItem('Электронная почта', user.email), // Email
                  _buildInfoItem(
                    'Отображаемое имя', // Nom affiché
                    user.displayName ?? 'Не задано', // Non défini
                  ),
                  _buildInfoItem(
                    'Фото профиля', // Photo de profil
                    user.hasPhoto ? 'Задана' : 'Не задана', // Définie / Non définie
                  ),
                  _buildInfoItem(
                    'Почта подтверждена', // Email vérifié
                    user.emailVerified == true ? 'Да' : 'Нет', // Oui / Non
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(
      BuildContext context,
      AppUser user,
      UserProvider userProvider,
      ) {
    TextEditingController nameController = TextEditingController(
      text: user.displayName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Изменить имя'), // Modifier mon nom
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Отображаемое имя', // Nom d'affichage
            hintText: 'Например: Иван Иванов', // Ex: Jean Dupont
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'), // Annuler
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (newName.isEmpty) return;

              try {
                await userProvider.updateDisplayName(newName);
                navigator.pop();

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Имя успешно обновлено'), // Nom mis à jour avec succès
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $e'), // Erreur: $e
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Сохранить'), // Sauvegarder
          ),
        ],
      ),
    );
  }
}*/