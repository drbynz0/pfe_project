import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/auth_service.dart';
import '/services/modify_password_service.dart'; // Importez le service de modification de mot de passe
import '/services/notification_service.dart'; // Importez le service de notifications
import '/services/language_service.dart'; // Importez le service de langue
import '/generated/l10n.dart';

class SettingsPage extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const SettingsPage({super.key, required this.onLocaleChange});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool biometricAuthEnabled = false;
  String currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    notificationsEnabled = await NotificationService.getNotificationsEnabled();
    currentLanguage = await LanguageService.getLanguageCode();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String? teacherId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: Text(S.of(context).settings, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _buildSectionTitle(S.of(context).profileAndAccount),
          _buildListTileWithLock(Icons.person, S.of(context).profile, () {
            Navigator.pushNamed(
              context,
              '/profile',
              arguments: {'teacherId': teacherId}, // Utilisez teacherId ici
            );
          }),
          _buildListTile(Icons.lock, S.of(context).password, () {
            showModifyPasswordDialog(context); // Utilisez la fonction de modification de mot de passe
          }),
          _buildListTile(Icons.logout, S.of(context).logout, () {
            _showLogoutDialog(context);
          }),

          _buildSectionTitle(S.of(context).notificationsAndAlerts),
          _buildSwitchTile(Icons.notifications, S.of(context).notifications, notificationsEnabled, (value) {
            setState(() {
              notificationsEnabled = value;
            });
            NotificationService.setNotificationsEnabled(value);
          }),
          _buildListTile(Icons.alarm, S.of(context).examReminders, () {}),

          _buildSectionTitle(S.of(context).displayAndAccessibility),
          _buildSwitchTile(Icons.dark_mode, S.of(context).darkMode, darkModeEnabled, (value) {
            setState(() {
              darkModeEnabled = value;
            });
          }),
          _buildListTile(Icons.language, S.of(context).language, () {
            _showLanguageDialog(context);
          }),

          _buildSectionTitle(S.of(context).securityAndPrivacy),
          _buildSwitchTile(Icons.fingerprint, S.of(context).biometricAuth, biometricAuthEnabled, (value) {
            setState(() {
              biometricAuthEnabled = value;
            });
          }),
          _buildListTile(Icons.vpn_key, S.of(context).manageSessions, () {
            _showManageSessionsDialog(context);
          }),
          _buildListTile(Icons.policy, S.of(context).privacyPolicy, () {}),

          _buildSectionTitle(S.of(context).about),
          _buildListTile(Icons.info, S.of(context).appVersion, () {}),
          _buildListTile(Icons.support, S.of(context).support, () {}),
        ],
      ),
    );
  }

  /// Widget pour afficher un titre de section
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  /// Widget pour une option de menu avec une icône et une action
  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  /// Widget pour une option de menu avec une icône, une action et un cadenas fermé
  Widget _buildListTileWithLock(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 18, color: Colors.red), // Ajout du cadenas fermé
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  /// Widget pour un switch (toggle)
  Widget _buildSwitchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Boîte de dialogue pour la déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            cardColor: const Color(0xFF2E2E2E), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
          ),
          child: AlertDialog(
            title: Text(S.of(context).logout),
            content: const Text("Voulez-vous vraiment vous déconnecter ?", style: TextStyle(color: Colors.white),),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  AuthService.logout(context);
                },
                child: Text(S.of(context).logout),
              ),
            ],
          ),
        );   
        }

    );
  }

  /// Boîte de dialogue pour la sélection de la langue
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            cardColor: const Color(0xFF2E2E2E), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
          ),
          child: AlertDialog(
            title: const Text("Sélectionner la langue", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("English", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    _changeLanguage('en');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text("Français", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    _changeLanguage('fr');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text("Español", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    _changeLanguage('es');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text("العربية", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    _changeLanguage('ar');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Boîte de dialogue pour gérer les sessions
  void _showManageSessionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            cardColor: const Color(0xFF2E2E2E), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
          ),
          child: AlertDialog(
            title: Text(S.of(context).manageSessions, style: TextStyle(color: Colors.white)),
            content: FutureBuilder<List<Session>>(
              future: AuthService.getActiveSessions(FirebaseAuth.instance.currentUser?.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Aucune session active trouvée.", style: TextStyle(color: Colors.white));
                }
                return StatefulBuilder(
                  builder: (context, setState) {
                    return SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final session = snapshot.data![index];
                          return ListTile(
                            title: Text(session.deviceName, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${session.lastActive}\n${session.devicePlatform}\n${session.deviceLocation}', style: const TextStyle(color: Colors.white70)),
                            trailing: IconButton(
                              icon: const Icon(Icons.logout, color: Colors.red),
                              onPressed: () {
                                _showConfirmationDialog(context, () async {
                                  await AuthService.logoutSession(session.sessionId, FirebaseAuth.instance.currentUser?.uid);
                                  setState(() {
                                    snapshot.data!.removeAt(index);
                                  });
                                });
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showConfirmationDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation", style: TextStyle(color: Colors.white)),
          content: const Text("Voulez-vous vraiment supprimer cette session ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text("Confirmer"),
            ),
          ],
        );
      },
    );
  }

  /// Changer la langue de l'application
  void _changeLanguage(String languageCode) async {
    await LanguageService.setLanguageCode(languageCode);
    setState(() {
      currentLanguage = languageCode;
    });
    widget.onLocaleChange(LanguageService.getLocale(languageCode));
  }
}
