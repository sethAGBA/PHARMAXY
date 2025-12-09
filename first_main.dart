import 'package:flutter/material.dart';

void main() {
  runApp(PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Pharmacie',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Écran de connexion
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    // Simulation de connexion
    if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade400],
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              padding: EdgeInsets.all(30),
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_pharmacy, size: 80, color: Colors.teal),
                  SizedBox(height: 20),
                  Text(
                    'Gestion Pharmacie',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Nom d\'utilisateur',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('CONNEXION'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Écran principal avec navigation
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    SalesScreen(),
    PrescriptionScreen(),
    StockScreen(),
    OrdersScreen(),
    CustomersScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pharmacie Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Tableau de bord'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale),
                label: Text('Vente'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.medical_services),
                label: Text('Ordonnances'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory),
                label: Text('Stock'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart),
                label: Text('Commandes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Clients'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart),
                label: Text('Rapports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Paramètres'),
              ),
            ],
          ),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// 1. Écran Tableau de bord
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tableau de bord',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'CA du jour',
                  value: '12 450 €',
                  icon: Icons.euro,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: DashboardCard(
                  title: 'Clients servis',
                  value: '87',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: DashboardCard(
                  title: 'Ordonnances',
                  value: '34',
                  icon: Icons.medical_services,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: DashboardCard(
                  title: 'Panier moyen',
                  value: '143 €',
                  icon: Icons.shopping_basket,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alertes importantes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        AlertItem(
                          icon: Icons.warning,
                          color: Colors.red,
                          title: '5 produits en rupture de stock',
                        ),
                        AlertItem(
                          icon: Icons.access_time,
                          color: Colors.orange,
                          title: '12 produits proches de la péremption',
                        ),
                        AlertItem(
                          icon: Icons.shopping_cart,
                          color: Colors.blue,
                          title: '3 commandes en attente de réception',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top 5 ventes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        TopSaleItem(name: 'Doliprane 1000mg', qty: '45'),
                        TopSaleItem(name: 'Efferalgan 500mg', qty: '32'),
                        TopSaleItem(name: 'Spasfon', qty: '28'),
                        TopSaleItem(name: 'Gaviscon', qty: '24'),
                        TopSaleItem(name: 'Smecta', qty: '21'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Icon(icon, color: color),
              ],
            ),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlertItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  AlertItem({required this.icon, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}

class TopSaleItem extends StatelessWidget {
  final String name;
  final String qty;

  TopSaleItem({required this.name, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name)),
          Text(qty, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// 2. Écran de vente
class SalesScreen extends StatefulWidget {
  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<SaleItem> cart = [];
  double total = 0;

  void addToCart(String name, double price) {
    setState(() {
      cart.add(SaleItem(name: name, price: price, quantity: 1));
      calculateTotal();
    });
  }

  void calculateTotal() {
    total = cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  void checkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total à payer: ${total.toStringAsFixed(2)} €'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  cart.clear();
                  total = 0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vente enregistrée avec succès')),
                );
              },
              child: Text('Espèces'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  cart.clear();
                  total = 0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vente enregistrée avec succès')),
                );
              },
              child: Text('Carte bancaire'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Point de vente',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Scanner ou rechercher un produit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Produits populaires',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      ProductCard(
                        name: 'Doliprane 1000mg',
                        price: 2.50,
                        onTap: () => addToCart('Doliprane 1000mg', 2.50),
                      ),
                      ProductCard(
                        name: 'Efferalgan 500mg',
                        price: 3.20,
                        onTap: () => addToCart('Efferalgan 500mg', 3.20),
                      ),
                      ProductCard(
                        name: 'Spasfon',
                        price: 5.80,
                        onTap: () => addToCart('Spasfon', 5.80),
                      ),
                      ProductCard(
                        name: 'Gaviscon',
                        price: 4.50,
                        onTap: () => addToCart('Gaviscon', 4.50),
                      ),
                      ProductCard(
                        name: 'Smecta',
                        price: 3.90,
                        onTap: () => addToCart('Smecta', 3.90),
                      ),
                      ProductCard(
                        name: 'Paracétamol',
                        price: 2.10,
                        onTap: () => addToCart('Paracétamol', 2.10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 350,
          color: Colors.grey[100],
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panier',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Divider(),
              Expanded(
                child: cart.isEmpty
                    ? Center(child: Text('Panier vide'))
                    : ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              title: Text(cart[index].name),
                              subtitle: Text('${cart[index].price.toStringAsFixed(2)} €'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        if (cart[index].quantity > 1) {
                                          cart[index].quantity--;
                                        } else {
                                          cart.removeAt(index);
                                        }
                                        calculateTotal();
                                      });
                                    },
                                  ),
                                  Text('${cart[index].quantity}'),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        cart[index].quantity++;
                                        calculateTotal();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: cart.isEmpty ? null : checkout,
                child: Text('PAYER'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SaleItem {
  String name;
  double price;
  int quantity;

  SaleItem({required this.name, required this.price, required this.quantity});
}

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final VoidCallback onTap;

  ProductCard({required this.name, required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medication, size: 30, color: Colors.teal),
              SizedBox(height: 5),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                '${price.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. Écran Ordonnances
class PrescriptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestion des ordonnances',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouvelle ordonnance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nom du patient',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Numéro de sécurité sociale',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.camera_alt),
                    label: Text('Scanner l\'ordonnance'),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Ajouter un médicament',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Médicaments prescrits',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DataTable(
                    columns: [
                      DataColumn(label: Text('Médicament')),
                      DataColumn(label: Text('Posologie')),
                      DataColumn(label: Text('Durée')),
                      DataColumn(label: Text('Prix')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      DataRow(cells: [
                        DataCell(Text('Doliprane 1000mg')),
                        DataCell(Text('3x/jour')),
                        DataCell(Text('7 jours')),
                        DataCell(Text('5.25 €')),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {},
                          ),
                        ),
                      ]),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: Text('Vérifier interactions'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text('Télétransmettre'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. Écran Stock
class StockScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gestion des stocks',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.add),
                    label: Text('Ajouter un produit'),
                  ),
                ],
              ),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Rechercher un produit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Code CIP')),
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Famille')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Seuil')),
                  DataColumn(label: Text('Prix achat')),
                  DataColumn(label: Text('Prix vente')),
                  DataColumn(label: Text('Péremption')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  _buildStockRow('3400930000000', 'Doliprane 1000mg', 'Antalgique', 
                      '150', '20', '1.80 €', '2.50 €', '12/2025', Colors.green),
                  _buildStockRow('3400930000001', 'Efferalgan 500mg', 'Antalgique', 
                      '12', '20', '2.30 €', '3.20 €', '03/2025', Colors.orange),
                  _buildStockRow('3400930000002', 'Spasfon', 'Antispasmodique', 
                      '0', '10', '4.20 €', '5.80 €', '08/2025', Colors.red),
                  _buildStockRow('3400930000003', 'Gaviscon', 'Antiacide', 
                      '45', '15', '3.20 €', '4.50 €', '11/2025', Colors.green),
                  _buildStockRow('3400930000004', 'Smecta', 'Antidiarrhéique', 
                      '28', '10', '2.80 €', '3.90 €', '01/2025', Colors.orange),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildStockRow(String cip, String name, String family, String stock, 
      String threshold, String buyPrice, String sellPrice, String expiry, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(cip)),
        DataCell(Text(name)),
        DataCell(Text(family)),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              stock,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(Text(threshold)),
        DataCell(Text(buyPrice)),
        DataCell(Text(sellPrice)),
        DataCell(Text(expiry)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 5. Écran Commandes
class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gestion des commandes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add),
                label: Text('Nouvelle commande'),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Icon(Icons.pending_actions, size: 40, color: Colors.orange),
                        SizedBox(height: 10),
                        Text('En attente', style: TextStyle(fontSize: 16)),
                        Text('5', style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping, size: 40, color: Colors.blue),
                        SizedBox(height: 10),
                        Text('En cours', style: TextStyle(fontSize: 16)),
                        Text('3', style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, size: 40, color: Colors.green),
                        SizedBox(height: 10),
                        Text('Reçues', style: TextStyle(fontSize: 16)),
                        Text('12', style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commandes récentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  DataTable(
                    columns: [
                      DataColumn(label: Text('N° Commande')),
                      DataColumn(label: Text('Fournisseur')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Montant')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      _buildOrderRow('CMD-2024-001', 'Grossiste A', '05/12/2024', 
                          '1 245 €', 'En attente', Colors.orange),
                      _buildOrderRow('CMD-2024-002', 'Laboratoire B', '04/12/2024', 
                          '850 €', 'En cours', Colors.blue),
                      _buildOrderRow('CMD-2024-003', 'Grossiste A', '03/12/2024', 
                          '2 340 €', 'Reçue', Colors.green),
                      _buildOrderRow('CMD-2024-004', 'Laboratoire C', '02/12/2024', 
                          '680 €', 'Reçue', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildOrderRow(String orderNum, String supplier, String date, 
      String amount, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(orderNum)),
        DataCell(Text(supplier)),
        DataCell(Text(date)),
        DataCell(Text(amount, style: TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.visibility, color: Colors.blue, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.print, color: Colors.grey, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 6. Écran Clients
class CustomersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gestion des clients',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.person_add),
                    label: Text('Nouveau client'),
                  ),
                ],
              ),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Rechercher un client',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: [
                DataColumn(label: Text('Nom')),
                DataColumn(label: Text('Téléphone')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('N° SS')),
                DataColumn(label: Text('Mutuelle')),
                DataColumn(label: Text('Dernière visite')),
                DataColumn(label: Text('Points fidélité')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                _buildCustomerRow('Dupont Marie', '06 12 34 56 78', 'marie.dupont@email.com',
                    '1 87 05 75 123 456 12', 'MGEN', '08/12/2024', '245'),
                _buildCustomerRow('Martin Pierre', '06 98 76 54 32', 'p.martin@email.com',
                    '1 92 03 68 234 567 23', 'Harmonie', '07/12/2024', '128'),
                _buildCustomerRow('Bernard Sophie', '07 23 45 67 89', 'sophie.b@email.com',
                    '2 85 11 45 345 678 34', 'MAIF', '05/12/2024', '387'),
                _buildCustomerRow('Dubois Jean', '06 34 56 78 90', 'j.dubois@email.com',
                    '1 78 09 82 456 789 45', 'Mutuelle Générale', '04/12/2024', '92'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildCustomerRow(String name, String phone, String email, 
      String ss, String mutuelle, String lastVisit, String points) {
    return DataRow(
      cells: [
        DataCell(Text(name)),
        DataCell(Text(phone)),
        DataCell(Text(email)),
        DataCell(Text(ss)),
        DataCell(Text(mutuelle)),
        DataCell(Text(lastVisit)),
        DataCell(
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              points,
              style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.visibility, color: Colors.blue, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.green, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 7. Écran Rapports
class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rapports et statistiques',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CA Mensuel',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '245 680 €',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.green, size: 16),
                            Text(
                              ' +12.5% vs mois dernier',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marge Moyenne',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '28.5%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.trending_down, color: Colors.red, size: 16),
                            Text(
                              ' -1.2% vs mois dernier',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Évolution du CA (7 derniers jours)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Graphique d\'évolution du CA',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ventes par famille',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 15),
                        _buildFamilyItem('Antalgiques', '35%', Colors.blue),
                        _buildFamilyItem('Antibiotiques', '22%', Colors.green),
                        _buildFamilyItem('Dermatologie', '18%', Colors.orange),
                        _buildFamilyItem('Cardiologie', '15%', Colors.red),
                        _buildFamilyItem('Autres', '10%', Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top 10 produits',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 15),
                        _buildTopProductItem('1', 'Doliprane 1000mg', '245', '612 €'),
                        _buildTopProductItem('2', 'Efferalgan 500mg', '198', '534 €'),
                        _buildTopProductItem('3', 'Spasfon', '167', '485 €'),
                        _buildTopProductItem('4', 'Gaviscon', '143', '428 €'),
                        _buildTopProductItem('5', 'Smecta', '128', '398 €'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyItem(String name, String percentage, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(name)),
          Text(
            percentage,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(String rank, String name, String qty, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '$qty unités',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// 8. Écran Paramètres
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.store),
                  title: Text('Informations pharmacie'),
                  subtitle: Text('Nom, adresse, numéro FINESS'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Utilisateurs'),
                  subtitle: Text('Gestion des comptes et permissions'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.receipt),
                  title: Text('Configuration caisse'),
                  subtitle: Text('TPE, imprimantes, format tickets'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.health_and_safety),
                  title: Text('Tiers payant'),
                  subtitle: Text('Configuration organismes et télétransmission'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text('Tarifs et marges'),
                  subtitle: Text('Configuration des prix de vente'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.backup),
                  title: Text('Sauvegarde'),
                  subtitle: Text('Sauvegardes automatiques et restauration'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.update),
                  title: Text('Mises à jour'),
                  subtitle: Text('Version actuelle: 2.5.1'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Aide et support'),
                  subtitle: Text('Documentation et assistance'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations système',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  _buildInfoRow('Version', '2.5.1'),
                  _buildInfoRow('Licence', 'Active jusqu\'au 31/12/2025'),
                  _buildInfoRow('Dernière sauvegarde', '09/12/2024 à 08:30'),
                  _buildInfoRow('Base de données', '2.4 Go'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}