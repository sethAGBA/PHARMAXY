import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/sale_models.dart';
import '../services/product_service.dart';
import '../services/sales_service.dart';

class VenteCaisseScreen extends StatefulWidget {
  const VenteCaisseScreen({super.key});

  @override
  State<VenteCaisseScreen> createState() => _VenteCaisseScreenState();
}

class _VenteCaisseScreenState extends State<VenteCaisseScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _historySearchController = TextEditingController();
  final List<CartItem> _cartItems = [];
  List<Product> _availableProducts = [];
  Product? _selectedProduct;

  double _remisePercentage = 0;
  String _selectedPaymentMethod = 'Espèces';
  late AnimationController _animationController;
  List<SaleRecord> _salesHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await ProductService.instance.fetchProductsForSale();
    final history = await SalesService.instance.fetchSalesHistory(limit: 30);
    setState(() {
      _availableProducts = products;
      _salesHistory = history;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _historySearchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double get _sousTotal => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _montantRemise => _sousTotal * (_remisePercentage / 100);
  double get _total => _sousTotal - _montantRemise;

  List<Product> get _filteredProducts {
    final search = _searchController.text.toLowerCase();
    final filtered = _availableProducts.where((p) {
      return p.name.toLowerCase().contains(search) || p.barcode.contains(search);
    }).toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  List<SaleRecord> get _filteredSalesHistory {
    final search = _historySearchController.text.toLowerCase();
    return _salesHistory.where((sale) {
      return sale.id.toLowerCase().contains(search) ||
          sale.paymentMethod.toLowerCase().contains(search) ||
          (sale.customer?.toLowerCase().contains(search) ?? false);
    }).toList();
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.barcode == product.barcode);
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(
          CartItem(
            name: product.name,
            barcode: product.barcode,
            price: product.price,
            quantity: 1,
            category: product.category,
          ),
        );
      }
    });
    _animationController.forward(from: 0);
  }

  void _removeFromCart(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        _cartItems[index].quantity = newQuantity;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  void _scanBarcode() {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;
    final product = _availableProducts.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => Product('Produit introuvable', '', 0, ''),
    );
    if (product.price > 0) {
      _addToCart(product);
      _barcodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} ajouté au panier'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code-barres invalide'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _remisePercentage = 0;
    });
  }

  void _completeTransaction() {
    final saleId = 'CMD-${DateTime.now().millisecondsSinceEpoch}';
    SalesService.instance.recordSale(
      id: saleId,
      total: _total,
      paymentMethod: _selectedPaymentMethod,
      type: 'Vente comptoir',
      clientId: '',
    );
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paiement effectué avec succès'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
    _clearCart();
  }

  void _processPayment() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le panier est vide'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    showDialog(context: context, builder: (_) => _buildPaymentDialog());
  }

  void _selectProduct(Product product) {
    setState(() => _selectedProduct = product);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On enlève la contrainte de hauteur fixe pour l'historique
          final rowHeight = constraints.maxHeight - 24;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(palette),
                  const SizedBox(height: 24),

                  // === SECTION PRINCIPALE : Scan + Produits + Panier + Totaux ===
                  SizedBox(
                    height: rowHeight > 420 ? rowHeight : 420,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildLeftColumn(palette)),
                        const SizedBox(width: 20),
                        SizedBox(width: 420, child: _buildRightColumn(palette)),
                      ],
                    ),
                  ),

                  // === ESPACE POUR DESCENDRE L'HISTORIQUE ===
                  const SizedBox(height: 40),

                  // === HISTORIQUE DES VENTES TOUT EN BAS ===
                  _buildSalesHistoryTable(palette, height: 360),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Point de Vente',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Scan, vente et encaissement',
              style: TextStyle(fontSize: 16, color: palette.subText),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.point_of_sale, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Caisse Active',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(ThemeColors palette) {
    return Column(
      children: [
        _buildScanSearch(palette),
        const SizedBox(height: 20),
        Expanded(child: _buildProductsGrid(palette)),
      ],
    );
  }

  Widget _buildScanSearch(ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  style: TextStyle(color: palette.text, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Scannez ou saisissez le code-barres',
                    hintStyle: TextStyle(color: palette.subText),
                    prefixIcon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
                    filled: true,
                    fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _scanBarcode(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _scanBarcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add_shopping_cart, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: TextStyle(color: palette.text),
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              hintStyle: TextStyle(color: palette.subText),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
              filled: true,
              fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(ThemeColors palette) {
    final products = _filteredProducts;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Produits Disponibles', palette),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) => _buildProductCard(products[index], palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, ThemeColors palette) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3B82F6).withOpacity(0.2),
              const Color(0xFF3B82F6).withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medication, color: Color(0xFF3B82F6), size: 32),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: TextStyle(color: palette.text, fontWeight: FontWeight.w600, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${product.price.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightColumn(ThemeColors palette) {
    return Column(
      children: [
        Expanded(child: _buildCart(palette)),
        const SizedBox(height: 20),
        _buildTotals(palette),
      ],
    );
  }

  Widget _buildCart(ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Panier (${_cartItems.length})',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text),
              ),
              if (_cartItems.isNotEmpty)
                IconButton(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.delete_sweep, color: Color(0xFFEF4444)),
                  tooltip: 'Vider le panier',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: palette.subText.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('Panier vide', style: TextStyle(color: palette.subText, fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(_cartItems[index], index, palette),
                  ),
          ),
        ],
      ),
    );
  }

  // HISTORIQUE TOUT EN BAS
  Widget _buildSalesHistoryTable(ThemeColors palette, {double height = 360}) {
    final history = _filteredSalesHistory;
    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(palette),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Historique du jour', palette),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _historySearchController,
                    style: TextStyle(color: palette.text),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un ticket...',
                      hintStyle: TextStyle(color: palette.subText),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: palette.divider),
            const SizedBox(height: 12),
            if (history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Aucune vente enregistrée', style: TextStyle(color: palette.subText)),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    _historyHeaderRow(palette),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) => _historyDataRow(history[index], palette),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _historyHeaderRow(ThemeColors palette) {
    return Row(
      children: [
        _historyCell('Ticket', palette, flex: 2, isHeader: true),
        _historyCell('Heure', palette, isHeader: true),
        _historyCell('Montant', palette, isHeader: true),
        _historyCell('Paiement', palette, isHeader: true),
        _historyCell('Client', palette, isHeader: true),
        _historyCell('Action', palette, isHeader: true, alignEnd: true),
      ],
    );
  }

  Widget _historyDataRow(SaleRecord sale, ThemeColors palette) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          _historyCell(sale.id, palette, flex: 2),
          _historyCell(sale.timeLabel, palette),
          _historyCell('${sale.total.toStringAsFixed(0)} FCFA', palette),
          _historyCell(sale.paymentMethod, palette),
          _historyCell(sale.customer ?? 'Client', palette),
          _historyCell(
            '',
            palette,
            alignEnd: true,
            child: TextButton(
              onPressed: () {},
              child: const Text('Ticket'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCell(
    String text,
    ThemeColors palette, {
    int flex = 1,
    bool isHeader = false,
    bool alignEnd = false,
    Widget? child,
  }) {
    final content = child ??
        Text(
          text,
          style: TextStyle(
            color: palette.text,
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          ),
        );
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: content,
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index, ThemeColors palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF10B981).withOpacity(0.2), const Color(0xFF10B981).withOpacity(0.4)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(color: palette.text, fontWeight: FontWeight.w600, fontSize: 15)),
                Text('${item.price.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Color(0xFF10B981), fontSize: 13)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _updateQuantity(index, item.quantity - 1),
                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(color: palette.text, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: () => _updateQuantity(index, item.quantity + 1),
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(0)} F',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeFromCart(index),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Remise', style: TextStyle(color: palette.subText, fontSize: 16)),
              SizedBox(
                width: 120,
                child: TextField(
                  style: TextStyle(color: palette.text),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: palette.subText),
                    suffixText: '%',
                    suffixStyle: TextStyle(color: palette.subText),
                    filled: true,
                    fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => setState(() => _remisePercentage = double.tryParse(value) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: palette.divider),
          const SizedBox(height: 16),
          _buildTotalRow('Sous-total', _sousTotal, false, palette),
          const SizedBox(height: 12),
          _buildTotalRow('Remise', _montantRemise, false, palette, color: const Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Divider(color: palette.divider, thickness: 2),
          const SizedBox(height: 16),
          _buildTotalRow('TOTAL', _total, true, palette),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildPaymentMethodButton('Espèces', Icons.money, palette)),
              const SizedBox(width: 8),
              Expanded(child: _buildPaymentMethodButton('Carte', Icons.credit_card, palette)),
              const SizedBox(width: 8),
              Expanded(child: _buildPaymentMethodButton('Mobile', Icons.phone_android, palette)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: const Color(0xFF10B981).withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.payment, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'PAYER',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isTotal, ThemeColors palette, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? (isTotal ? palette.text : palette.subText),
            fontSize: isTotal ? 22 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            color: color ?? (isTotal ? const Color(0xFF10B981) : palette.text),
            fontSize: isTotal ? 24 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodButton(String method, IconData icon, ThemeColors palette) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF3B82F6)]) : null,
          color: isSelected ? null : (palette.isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : palette.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : palette.subText, size: 24),
            const SizedBox(height: 4),
            Text(
              method,
              style: TextStyle(
                color: isSelected ? Colors.white : palette.subText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDialog() {
    final palette = ThemeColors.from(context);
    final montantDonneController = TextEditingController();
    double montantDonne = 0;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        final monnaie = montantDonne - _total;
        return AlertDialog(
          backgroundColor: palette.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFF10B981), size: 32),
              const SizedBox(width: 12),
              Text('Finaliser le Paiement', style: TextStyle(color: palette.text, fontSize: 22)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF10B981).withOpacity(0.2), const Color(0xFF10B981).withOpacity(0.4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Montant à payer', style: TextStyle(color: palette.subText, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        '${_total.toStringAsFixed(0)} FCFA',
                        style: TextStyle(color: palette.text, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Méthode: $_selectedPaymentMethod', style: TextStyle(color: palette.subText, fontSize: 16)),
                const SizedBox(height: 16),
                if (_selectedPaymentMethod == 'Espèces') ...[
                  TextField(
                    controller: montantDonneController,
                    style: TextStyle(color: palette.text, fontSize: 20),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant donné',
                      labelStyle: TextStyle(color: palette.subText),
                      suffixText: 'FCFA',
                      suffixStyle: TextStyle(color: palette.subText),
                      filled: true,
                      fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setDialogState(() => montantDonne = double.tryParse(value) ?? 0),
                  ),
                  const SizedBox(height: 16),
                  if (monnaie >= 0 && montantDonne > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monnaie à rendre:', style: TextStyle(color: palette.subText, fontSize: 16)),
                          Text(
                            '${monnaie.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: palette.subText, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_selectedPaymentMethod == 'Espèces' && montantDonne < _total) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Montant insuffisant'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _completeTransaction();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Confirmer le Paiement', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  // Helpers
  BoxDecoration _cardDecoration(ThemeColors palette) {
    return BoxDecoration(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text, ThemeColors palette) {
    return Text(
      text,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text),
    );
  }
}
