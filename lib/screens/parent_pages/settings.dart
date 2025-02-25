import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool biometricAuthEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF082E4A),
      appBar: AppBar(
        title: const Text("Paramètres", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF140C5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          _buildSectionTitle("👤 Profil & Compte"),
          _buildListTile(Icons.person, "Modifier le profil", () {
            Navigator.pushNamed(context, '/profile');
          }),
          _buildListTile(Icons.lock, "Changer le mot de passe", () {}),
          _buildListTile(Icons.logout, "Déconnexion", () {
            _showLogoutDialog(context);
          }),

          _buildSectionTitle("🔔 Notifications & Alertes"),
          _buildSwitchTile(Icons.notifications, "Recevoir les notifications", notificationsEnabled, (value) {
            setState(() {
              notificationsEnabled = value;
            });
          }),
          _buildListTile(Icons.alarm, "Rappels d'examens", () {}),

          _buildSectionTitle("🎨 Affichage & Accessibilité"),
          _buildSwitchTile(Icons.dark_mode, "Mode sombre", darkModeEnabled, (value) {
            setState(() {
              darkModeEnabled = value;
            });
          }),
          _buildListTile(Icons.language, "Langue", () {}),

          _buildSectionTitle("🔒 Sécurité & Confidentialité"),
          _buildSwitchTile(Icons.fingerprint, "Authentification biométrique", biometricAuthEnabled, (value) {
            setState(() {
              biometricAuthEnabled = value;
            });
          }),
          _buildListTile(Icons.vpn_key, "Gérer les sessions", () {}),
          _buildListTile(Icons.policy, "Politique de confidentialité", () {}),

          _buildSectionTitle("ℹ️ À propos"),
          _buildListTile(Icons.info, "Version de l'application", () {}),
          _buildListTile(Icons.support, "Support technique", () {}),
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

  /// Widget pour un switch (toggle)
  Widget _buildSwitchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Boîte de dialogue pour la déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Déconnexion"),
          ),
        ],
      ),
    );
  }
}
