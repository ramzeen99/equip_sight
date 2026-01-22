import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equip_sight/model/user_model.dart';
import 'package:equip_sight/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            backgroundImage: user.hasPhoto
                ? NetworkImage(user.photoURL!)
                : null,
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

          _buildBadge(Icons.flag, "Pays", user.countryId ?? "Non défini"),
          _buildBadge(
            Icons.location_city,
            "Ville",
            user.cityId ?? "Non défini",
          ),
          _buildBadge(
            Icons.school,
            "Université",
            user.universityId ?? "Non défini",
          ),
          _buildBadge(Icons.apartment, "Dortoir", user.dormId ?? "Non défini"),

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
                  onTap: () =>
                      _showEditLocationDialog(context, user, userProvider),
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
    final controller = TextEditingController(
      text: userProvider.currentUser?.displayName,
    );

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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              await userProvider.updateProfile(displayName: newName);
              if (!context.mounted) return;
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

    String? newCountry = user.countryId;
    String? newCity = user.cityId;
    String? newUniversity = user.universityId;
    String? newDorm = user.dormId;

    List<String> countryList = (await firestore.collection('countries').get())
        .docs
        .map((e) => e.id)
        .toList();
    List<String> cityList = [];
    List<String> uniList = [];
    List<String> dormList = [];

    if (newCountry != null) {
      cityList =
          (await firestore
                  .collection('countries')
                  .doc(newCountry)
                  .collection('cities')
                  .get())
              .docs
              .map((e) => e.id)
              .toList();
    }

    if (newCountry != null && newCity != null) {
      uniList =
          (await firestore
                  .collection('countries')
                  .doc(newCountry)
                  .collection('cities')
                  .doc(newCity)
                  .collection('universities')
                  .get())
              .docs
              .map((e) => e.id)
              .toList();
    }

    if (newCountry != null && newCity != null && newUniversity != null) {
      dormList =
          (await firestore
                  .collection('countries')
                  .doc(newCountry)
                  .collection('cities')
                  .doc(newCity)
                  .collection('universities')
                  .doc(newUniversity)
                  .collection('dorms')
                  .get())
              .docs
              .map((e) => e.id)
              .toList();
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Modifier dortoir & localisation"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField(
                    initialValue: newCountry,
                    items: countryList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
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

                      cityList =
                          (await firestore
                                  .collection('countries')
                                  .doc(v)
                                  .collection('cities')
                                  .get())
                              .docs
                              .map((e) => e.id)
                              .toList();
                      setStateDialog(() {});
                    },
                    decoration: InputDecoration(labelText: "Pays"),
                  ),
                  DropdownButtonFormField(
                    initialValue: newCity,
                    items: cityList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) async {
                      setStateDialog(() {
                        newCity = v;
                        newUniversity = null;
                        newDorm = null;
                        uniList = [];
                        dormList = [];
                      });

                      uniList =
                          (await firestore
                                  .collection('countries')
                                  .doc(newCountry)
                                  .collection('cities')
                                  .doc(v)
                                  .collection('universities')
                                  .get())
                              .docs
                              .map((e) => e.id)
                              .toList();
                      setStateDialog(() {});
                    },
                    decoration: InputDecoration(labelText: "Ville"),
                  ),
                  DropdownButtonFormField(
                    initialValue: newUniversity,
                    items: uniList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) async {
                      setStateDialog(() {
                        newUniversity = v;
                        newDorm = null;
                        dormList = [];
                      });

                      dormList =
                          (await firestore
                                  .collection('countries')
                                  .doc(newCountry)
                                  .collection('cities')
                                  .doc(newCity)
                                  .collection('universities')
                                  .doc(v)
                                  .collection('dorms')
                                  .get())
                              .docs
                              .map((e) => e.id)
                              .toList();
                      setStateDialog(() {});
                    },
                    decoration: InputDecoration(labelText: "Université"),
                  ),
                  DropdownButtonFormField(
                    initialValue: newDorm,
                    items: dormList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setStateDialog(() => newDorm = v),
                    decoration: InputDecoration(labelText: "Dortoir"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annuler"),
                ),
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
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text("Sauvegarder"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
