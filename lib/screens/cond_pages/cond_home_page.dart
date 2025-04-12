import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:p_f_e_project/screens/cond_pages/suivi_bus.dart';
import 'package:p_f_e_project/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'messages_page.dart';
import '/screens/cond_pages/settings.dart';
import '/providers/locale_provider.dart';

class CondHomePage extends StatefulWidget {
  const CondHomePage({super.key});
  
  @override
  CondHomePageState createState() => CondHomePageState();
}

class CondHomePageState extends State<CondHomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final List<String> notifications = [];
  final List<BusRoute> plannedRoutes = [];
  final List<DailyStat> dailyStats = [];

  @override
  void initState() {
    super.initState();
    
    // Initialisation des données de démonstration
    _initializeDemoData();
    
    _pages = [
      HomeScreen(routes: plannedRoutes, stats: dailyStats),
      const MessagesPage(),
      SuiviBusPage(),
      SettingsPage(onLocaleChange: (locale) {
        Provider.of<LocaleProvider>(context, listen: false).setLocale(locale);
      }),
    ];
  }

  void _initializeDemoData() {
    // Itinéraires planifiés
    plannedRoutes.addAll([
      BusRoute(
        routeName: "Ligne 1 - Matin",
        startTime: DateTime.now().subtract(const Duration(hours: 3)),
        endTime: DateTime.now().subtract(const Duration(hours: 2)),
        stops: ["École A", "Arrêt B", "Arrêt C", "École Principale"],
        status: "Terminé",
      ),
      BusRoute(
        routeName: "Ligne 2 - Midi",
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        stops: ["École Principale", "Arrêt D", "Arrêt E"],
        status: "Planifié",
      ),
    ]);

    // Statistiques quotidiennes
    dailyStats.addAll([
      DailyStat(day: "Lun", completed: 4, planned: 5),
      DailyStat(day: "Mar", completed: 5, planned: 5),
      DailyStat(day: "Mer", completed: 3, planned: 5),
      DailyStat(day: "Jeu", completed: 5, planned: 5),
      DailyStat(day: "Ven", completed: 2, planned: 4),
      DailyStat(day: "Sam", completed: 0, planned: 0),
      DailyStat(day: "Dim", completed: 0, planned: 0),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 35, 51),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'School App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter Tight',
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 25, 40, 62),
        actions: [
          _buildNotificationButton(),
          _buildProfileMenu(),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildNotificationButton() {
    return IconButton(
      icon: Badge(
        smallSize: 8,
        isLabelVisible: notifications.isNotEmpty,
        child: const Icon(Icons.notifications, color: Colors.white, size: 24),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Notifications',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: notifications.isEmpty
                ? const Text('Aucune nouvelle notification.')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (_, index) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(notifications[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setState(() {
                                notifications.removeAt(index);
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileMenu() {
    return PopupMenuButton<String>(
        icon: Icon(Icons.account_circle, color: Colors.white, size: 30),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.pushNamed(context, '/profile');
        } else if (value == 'logout') {
          AuthService.logout(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Text('Mon Profil'),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Déconnexion', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_bus_outlined),
          activeIcon: Icon(Icons.directions_bus),
          label: 'Suivi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Réglages',
        ),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color.fromARGB(255, 19, 20, 40),
      unselectedItemColor: const Color.fromARGB(255, 87, 99, 108),
      selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 8,
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<BusRoute> routes;
  final List<DailyStat> stats;
  
  const HomeScreen({super.key, required this.routes, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodayRoutes(routes),
          const SizedBox(height: 20),
          _buildStatsChart(stats),
          const SizedBox(height: 20),
          _buildRecentActivity(routes),
        ],
      ),
    );
  }

  Widget _buildTodayRoutes(List<BusRoute> routes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Itinéraires',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...routes.map((route) => _buildRouteCard(route)),
      ],
    );
  }

  Widget _buildRouteCard(BusRoute route) {
    return Card(
      color: const Color.fromARGB(255, 26, 38, 65),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  route.routeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                Chip(
                  label: Text(route.status),
                  backgroundColor: route.status == "Terminé" 
                      ? Colors.green[50] 
                      : Colors.blue[50],
                  labelStyle: TextStyle(
                    color: route.status == "Terminé" 
                        ? Colors.green 
                        : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('HH:mm').format(route.startTime)} - ${DateFormat('HH:mm').format(route.endTime)}',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Arrêts:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ...route.stops.map((stop) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                '• $stop',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsChart(List<DailyStat> stats) {
    return Card(
      color: const Color.fromARGB(255, 28, 47, 79),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Hebdomadaires',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<DailyStat, String>(
                    dataSource: stats,
                    xValueMapper: (DailyStat stat, _) => stat.day,
                    yValueMapper: (DailyStat stat, _) => stat.completed,
                    name: 'Terminés',
                    color: const Color.fromARGB(255, 126, 211, 236),
                  ),
                  ColumnSeries<DailyStat, String>(
                    dataSource: stats,
                    xValueMapper: (DailyStat stat, _) => stat.day,
                    yValueMapper: (DailyStat stat, _) => stat.planned,
                    name: 'Planifiés',
                    color: const Color.fromARGB(255, 94, 104, 118),
                  ),
                ],
                legend: Legend(
                  
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<BusRoute> routes) {
    final completedRoutes = routes.where((r) => r.status == "Terminé").toList();
    
    if (completedRoutes.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité Récente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...completedRoutes.map((route) => ListTile(
          leading: const Icon(Icons.directions_bus, color: Color.fromARGB(255, 42, 132, 196)),
          title: Text(route.routeName, 
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            'Terminé à ${DateFormat('HH:mm').format(route.endTime)}',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        )),
      ],
    );
  }
}

// Modèles de données
class BusRoute {
  final String routeName;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> stops;
  final String status;

  BusRoute({
    required this.routeName,
    required this.startTime,
    required this.endTime,
    required this.stops,
    required this.status,
  });
}

class DailyStat {
  final String day;
  final int completed;
  final int planned;

  DailyStat({
    required this.day,
    required this.completed,
    required this.planned,
  });
}