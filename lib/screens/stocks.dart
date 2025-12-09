// screens/stocks.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/product_service.dart';
import '../models/sale_models.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFamily = 'Toutes';
  String _selectedLab = 'Tous';
  String _selectedForm = 'Toutes';

  List<StockItem> _allItems = [];
  List<String> _familiesList = [];
  List<String> _labsList = [];
  List<String> _formsList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _loadStocks();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    final entries = await ProductService.instance.fetchStockEntries();
    
    // Extract unique values for filters
    final families = <String>{};
    final labs = <String>{};
    final forms = <String>{};
    
    setState(() {
      _allItems = entries
          .map(
            (e) => StockItem(
              id: e.id,
              name: e.name,
              code: e.cip.isNotEmpty ? e.cip : e.id,
              dci: e.dci,
              dosage: e.dosage,
              family: e.family,
              lab: e.lab,
              form: e.form,
              qtyOfficine: e.qtyOfficine,
              qtyReserve: e.qtyReserve,
              seuil: e.seuil,
              seuilMax: e.seuilMax,
              prixAchat: e.prixAchat,
              prixVente: e.prixVente,
              tva: e.tva,
              remboursement: e.remboursement,
              statut: e.statut,
              type: e.type,
              sku: e.sku,
              localisation: e.localisation,
              fournisseur: e.fournisseur,
              ordonnance: e.ordonnance,
              controle: e.controle,
              description: e.description,
              conditionnement: e.conditionnement,
              notice: e.notice,
              image: e.image,
              peremption: e.peremption,
              lot: e.lot,
              valeur: (e.qtyOfficine + e.qtyReserve) * e.prixVente,
            ),
          )
          .toList();
      
      // Build filter lists from actual data (keep 'Toutes'/'Tous' as last item)
      for (var item in _allItems) {
        if (item.family.isNotEmpty) families.add(item.family);
        if (item.lab.isNotEmpty) labs.add(item.lab);
        if (item.form.isNotEmpty) forms.add(item.form);
      }

      final famList = families.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final labList = labs.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final formList = forms.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      // Ensure the 'Toutes' / 'Tous' choice is last
      famList.removeWhere((s) => s.trim().isEmpty);
      labList.removeWhere((s) => s.trim().isEmpty);
      formList.removeWhere((s) => s.trim().isEmpty);

      famList.add('Toutes');
      labList.add('Tous');
      formList.add('Toutes');

      _familiesList = famList;
      _labsList = labList;
      _formsList = formList;
      
      _loading = false;
    });
  }

  Future<void> _openProductForm({StockItem? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dciCtrl = TextEditingController(text: existing?.dci ?? '');
    final cipCtrl = TextEditingController(text: existing?.code ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '');
    final familleCtrl = TextEditingController(text: existing?.family ?? '');
    final laboCtrl = TextEditingController(text: existing?.lab ?? '');
    final formeCtrl = TextEditingController(text: existing?.form ?? '');
    final achatCtrl = TextEditingController(text: existing?.prixAchat.toString() ?? '');
    final venteCtrl = TextEditingController(text: existing?.prixVente.toString() ?? '');
    final tvaCtrl = TextEditingController(text: existing?.tva.toString() ?? '');
    final rembCtrl = TextEditingController(text: existing?.remboursement.toString() ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final localisationCtrl = TextEditingController(text: existing?.localisation ?? '');
    final fournisseurCtrl = TextEditingController(text: existing?.fournisseur ?? '');
    final descriptionCtrl = TextEditingController(text: existing?.description ?? '');
    final seuilMaxCtrl = TextEditingController(text: (existing?.seuilMax ?? 0).toString());
    final noticeCtrl = TextEditingController(text: '');
    final imageCtrl = TextEditingController(text: '');
    final seuilCtrl = TextEditingController(text: existing?.seuil.toString() ?? '');
    final reserveCtrl = TextEditingController(text: existing?.qtyReserve.toString() ?? '');
    final officineCtrl = TextEditingController(text: existing?.qtyOfficine.toString() ?? '');
    final peremptionCtrl = TextEditingController(text: existing?.peremption ?? '');
    final lotCtrl = TextEditingController(text: existing?.lot ?? '');
    String typeValue = existing?.type.isNotEmpty == true ? existing!.type : 'Médicament';
    String statutValue = existing?.statut.isNotEmpty == true ? existing!.statut : 'Actif';
    String conditionnement = existing?.conditionnement.isNotEmpty == true ? existing!.conditionnement : 'Boîte';
    bool ordonnance = existing?.ordonnance ?? false;
    bool controle = existing?.controle ?? false;
    if (existing?.notice.isNotEmpty == true) noticeCtrl.text = existing!.notice;
    if (existing?.image.isNotEmpty == true) imageCtrl.text = existing!.image;
    bool advanced = existing != null &&
        (existing.type.isNotEmpty ||
            existing.sku.isNotEmpty ||
            existing.seuilMax > 0 ||
            existing.ordonnance ||
            existing.controle);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final palette = ThemeColors.from(context);
            final isWideDialog = MediaQuery.of(context).size.width > 1200;
            final marginValues = _computeMargin(achatCtrl.text, venteCtrl.text);

            return Dialog(
              backgroundColor: palette.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Container(
                constraints: BoxConstraints(maxWidth: isWideDialog ? 1100 : 960, maxHeight: MediaQuery.of(context).size.height * 0.9),
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_box_outlined, color: Colors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing == null ? 'Ajouter un produit' : 'Modifier le produit',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
                                ),
                                Text('Mode simple ou avancé • prix, lots, statut', style: TextStyle(color: palette.subText, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _modeChip('Simple', !advanced, palette, onTap: () => setModalState(() => advanced = false)),
                                const SizedBox(width: 8),
                                _modeChip('Avancé', advanced, palette, onTap: () => setModalState(() => advanced = true)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Form Content
                      Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _sectionHeader('Identité produit', palette),
                            _gridFields(
                              [
                                _formField(nameCtrl, 'Nom commercial', palette, requiredField: true, hint: 'Ex: Paracétamol 500mg'),
                                _formField(cipCtrl, 'CIP / Code-barres', palette, requiredField: true, hint: 'EAN ou code interne'),
                                _formField(dciCtrl, 'DCI', palette, hint: 'Substance active'),
                                _formField(dosageCtrl, 'Dosage / Présentation', palette, hint: '500mg, sirop 125ml...'),
                                _formField(familleCtrl, 'Famille thérapeutique', palette, hint: 'Antalgique, Antibiotique...'),
                                _formField(formeCtrl, 'Forme galénique', palette, hint: 'Comprimé, Gélule...'),
                                _formField(laboCtrl, 'Laboratoire', palette),
                                _formField(lotCtrl, 'Lot', palette, hint: 'LOT-XYZ-01'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _chipsRow(
                              label: 'Suggestions famille',
                              options: const ['Antalgique', 'Antibiotique', 'Antispasmodique', 'Anti-inflammatoire'],
                              onSelect: (value) => setModalState(() => familleCtrl.text = value),
                              palette: palette,
                            ),
                            const SizedBox(height: 16),
                            _sectionHeader('Tarification', palette),
                            _gridFields(
                              [
                                _formField(
                                  achatCtrl,
                                  'Prix achat (FCFA)',
                                  palette,
                                  keyboard: TextInputType.number,
                                  hint: '0',
                                  requiredField: true,
                                  onChanged: (_) => setModalState(() {}),
                                ),
                                _formField(
                                  venteCtrl,
                                  'Prix vente (FCFA)',
                                  palette,
                                  keyboard: TextInputType.number,
                                  hint: '0',
                                  requiredField: true,
                                  onChanged: (_) => setModalState(() {}),
                                ),
                                _formField(tvaCtrl, 'TVA (%)', palette, keyboard: TextInputType.number, hint: '18'),
                                _formField(rembCtrl, 'Remboursement (%)', palette, keyboard: TextInputType.number, hint: '0'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _marginBanner(palette, marginValues.percent, marginValues.value),
                            const SizedBox(height: 16),
                            _sectionHeader('Stocks & Traçabilité', palette),
                            _gridFields(
                              [
                                _formField(officineCtrl, 'Stock officine', palette, keyboard: TextInputType.number, hint: '0', requiredField: true),
                                _formField(reserveCtrl, 'Stock réserve', palette, keyboard: TextInputType.number, hint: '0', requiredField: true),
                            _formField(seuilCtrl, 'Seuil alerte', palette, keyboard: TextInputType.number, hint: 'Quantité min'),
                            _dateField(
                              context: context,
                              controller: peremptionCtrl,
                              label: 'Péremption',
                              palette: palette,
                              onPick: (value) => setModalState(() => peremptionCtrl.text = value),
                            ),
                              ],
                            ),
                            if (advanced) ...[
                              const SizedBox(height: 20),
                              _sectionHeader('Version avancée', palette),
                              _gridFields(
                                [
                              _formField(skuCtrl, 'SKU interne', palette, hint: 'Code interne'),
                              _formField(localisationCtrl, 'Localisation / Rayon', palette, hint: 'Allée, étagère...'),
                              _formField(seuilMaxCtrl, 'Seuil max', palette, keyboard: TextInputType.number, hint: 'Quantité max'),
                              _formField(fournisseurCtrl, 'Fournisseur principal', palette, hint: 'Grossiste'),
                              _dropdownField(
                                label: 'Conditionnement',
                                value: conditionnement,
                                items: const ['Boîte', 'Plaquette', 'Bouteille', 'Unité', 'Autre'],
                                onChanged: (v) => setModalState(() => conditionnement = v ?? 'Boîte'),
                                palette: palette,
                              ),
                              _dropdownField(
                                label: 'Type',
                                value: typeValue,
                                items: const ['Médicament', 'Dispositif médical', 'Parapharmacie', 'Accessoire'],
                                onChanged: (v) => setModalState(() => typeValue = v ?? 'Médicament'),
                                palette: palette,
                                  ),
                                  _dropdownField(
                                    label: 'Statut',
                                    value: statutValue,
                                    items: const ['Actif', 'Désactivé', 'Rupture'],
                                    onChanged: (v) => setModalState(() => statutValue = v ?? 'Actif'),
                                    palette: palette,
                                  ),
                                  _toggleField(
                                    label: 'Ordonnance requise',
                                    value: ordonnance,
                                    onChanged: (v) => setModalState(() => ordonnance = v),
                                    palette: palette,
                                  ),
                              _toggleField(
                                label: 'Médicament contrôlé',
                                value: controle,
                                onChanged: (v) => setModalState(() => controle = v),
                                palette: palette,
                              ),
                              _formField(descriptionCtrl, 'Description / précautions', palette, hint: 'Contre-indications...', keyboard: TextInputType.multiline),
                              _formField(noticeCtrl, 'Notice (URL/chemin)', palette, hint: 'notice.pdf'),
                              _formField(imageCtrl, 'Image (URL/chemin)', palette, hint: 'image.jpg'),
                            ],
                          ),
                        ],
                      ],
                    ),
                      ),
                      const SizedBox(height: 20),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              // reset fields when cancelling a creation
                              formKey.currentState?.reset();
                              Navigator.pop(context, false);
                            },
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_alt, size: 18),
                            onPressed: () {
                              final valid = formKey.currentState?.validate() ?? false;
                              if (valid) Navigator.pop(context, true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            label: const Text('Enregistrer'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    await ProductService.instance.upsertProduct(
      id: existing?.id,
      nom: nameCtrl.text.trim(),
      dci: dciCtrl.text.trim(),
      dosage: dosageCtrl.text.trim(),
      cip: cipCtrl.text.trim(),
      famille: familleCtrl.text.trim(),
      laboratoire: laboCtrl.text.trim(),
      forme: formeCtrl.text.trim(),
      prixAchat: int.tryParse(achatCtrl.text.trim()) ?? 0,
      prixVente: int.tryParse(venteCtrl.text.trim()) ?? 0,
      tva: int.tryParse(tvaCtrl.text.trim()) ?? 0,
      remboursement: int.tryParse(rembCtrl.text.trim()) ?? 0,
      sku: skuCtrl.text.trim(),
      type: typeValue,
      statut: statutValue,
      localisation: localisationCtrl.text.trim(),
      fournisseur: fournisseurCtrl.text.trim(),
      ordonnance: ordonnance,
      controle: controle,
      description: descriptionCtrl.text.trim(),
      conditionnement: conditionnement,
      notice: noticeCtrl.text.trim(),
      image: imageCtrl.text.trim(),
      seuilMax: int.tryParse(seuilMaxCtrl.text.trim()) ?? 0,
      seuil: int.tryParse(seuilCtrl.text.trim()) ?? 0,
      reserve: int.tryParse(reserveCtrl.text.trim()) ?? 0,
      officine: int.tryParse(officineCtrl.text.trim()) ?? 0,
      peremptionIso: peremptionCtrl.text.trim(),
      lot: lotCtrl.text.trim(),
    );
    await _loadStocks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Produit ajouté' : 'Produit mis à jour'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Widget _formField(
    TextEditingController ctrl,
    String label,
    ThemeColors palette, {
    bool requiredField = false,
    TextInputType keyboard = TextInputType.text,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: palette.isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: requiredField ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null : null,
    );
  }

  Widget _sectionHeader(String title, ThemeColors palette) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: palette.text)),
        ],
      ),
    );
  }

  Widget _gridFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 680;
        final width = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: fields.map((f) => SizedBox(width: width, child: f)).toList(),
        );
      },
    );
  }

  Widget _chipsRow({
    required String label,
    required List<String> options,
    required ValueChanged<String> onSelect,
    required ThemeColors palette,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: palette.subText)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (o) => GestureDetector(
                  onTap: () => onSelect(o),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.35)),
                    ),
                    child: Text(o, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ThemeColors palette,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: palette.isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: palette.subText),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required ThemeColors palette,
    required ValueChanged<String> onPick,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Sélectionner une date',
        suffixIcon: const Icon(Icons.event),
        filled: true,
        fillColor: palette.isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onTap: () async {
        // Use Navigator to get the root context for date picker
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        final now = DateTime.now();
        final initial = controller.text.isNotEmpty ? DateTime.tryParse(controller.text) ?? now : now;
        final picked = await showDatePicker(
          context: rootContext,
          initialDate: initial,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 10),
          helpText: 'Date de péremption',
          useRootNavigator: true,
        );
        if (picked != null) {
          final iso = picked.toIso8601String();
          controller.text = iso.substring(0, 10);
          onPick(controller.text);
        }
      },
    );
  }

  Widget _toggleField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeColors palette,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: palette.text))),
          Switch(
            value: value,
            activeColor: Colors.teal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _marginBanner(ThemeColors palette, double percent, double value) {
    final color = percent >= 0 ? Colors.teal : Colors.red;
    final icon = percent >= 0 ? Icons.trending_up : Icons.trending_down;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            'Marge estimée : ${percent.toStringAsFixed(1)}% (${value.toStringAsFixed(0)} FCFA)',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text('Basée sur Prix vente - Prix achat', style: TextStyle(color: palette.subText, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool active, ThemeColors palette, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.teal : palette.divider),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : palette.text, fontWeight: FontWeight.w700)),
      ),
    );
  }

  _MarginResult _computeMargin(String achat, String vente) {
    final achatVal = double.tryParse(achat) ?? 0;
    final venteVal = double.tryParse(vente) ?? 0;
    final value = venteVal - achatVal;
    final percent = achatVal == 0 ? 0.0 : (value / achatVal) * 100;
    return _MarginResult(percent: percent, value: value);
  }

  List<StockItem> get _filteredItems {
    return _allItems.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.code.contains(_searchController.text);
      final matchesFamily = _selectedFamily == 'Toutes' || item.family == _selectedFamily;
      final matchesLab = _selectedLab == 'Tous' || item.lab == _selectedLab;
      final matchesForm = _selectedForm == 'Toutes' || item.form == _selectedForm;
      return matchesSearch && matchesFamily && matchesLab && matchesForm;
    }).toList();
  }

  int get _totalValue => _filteredItems.fold(0, (sum, i) => sum + i.valeur);

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final accent = Colors.teal;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(palette),
            const SizedBox(height: 24),
            _buildFilters(palette),
            const SizedBox(height: 24),
            Expanded(
              child: _card(
                palette,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filteredItems.length} produits en stock',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: palette.text),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Valeur totale : $_totalValue FCFA',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) => _stockCard(_filteredItems[index], palette, accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gestion des stocks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: palette.text, letterSpacing: 1.2)),
                Text('Produits • Quantités • Péremption • Valorisation', style: TextStyle(fontSize: 16, color: palette.subText)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _openProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un produit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final searchWidth = constraints.maxWidth > 900 ? 420.0 : constraints.maxWidth - 40;
            return Wrap(
              spacing: 12,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 280, maxWidth: searchWidth),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit, code CIP...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                ),
                _filterDropdown(
                  palette,
                  'Famille',
                  _selectedFamily,
                  _familiesList,
                  (v) => setState(() => _selectedFamily = v!),
                  width: 190,
                ),
                _filterDropdown(
                  palette,
                  'Labo',
                  _selectedLab,
                  _labsList,
                  (v) => setState(() => _selectedLab = v!),
                  width: 170,
                ),
                _filterDropdown(
                  palette,
                  'Forme',
                  _selectedForm,
                  _formsList,
                  (v) => setState(() => _selectedForm = v!),
                  width: 170,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterDropdown(
    ThemeColors palette,
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: palette.subText),
      ),
    );
  }

  Widget _stockCard(StockItem item, ThemeColors palette, Color accent) {
    final total = item.qtyOfficine + item.qtyReserve;
    final isRupture = total == 0;
    final isAlerte = total <= item.seuil && total > 0;
    final isExpiring = item.peremption.contains('2025');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRupture
              ? Colors.red.withOpacity(0.35)
              : isAlerte
                  ? Colors.orange.withOpacity(0.3)
                  : palette.divider,
          width: isRupture || isAlerte ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isRupture
                ? Colors.red.withOpacity(0.15)
                : isAlerte
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
                    const SizedBox(height: 4),
                    Text(item.code, style: TextStyle(fontSize: 13, color: palette.subText, fontFamily: 'Roboto Mono')),
                    if (item.dci.isNotEmpty || item.dosage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [item.dci, item.dosage].where((e) => e.isNotEmpty).join(' • '),
                          style: TextStyle(fontSize: 13, color: palette.subText),
                        ),
                      ),
                  ],
                ),
              ),
              if (isRupture)
                const Icon(Icons.error, color: Colors.red, size: 30)
              else if (isAlerte)
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _infoChip('Famille', item.family, palette),
              _infoChip('Labo', item.lab, palette),
              _infoChip('Forme', item.form, palette),
              _infoChip('TVA', '${item.tva}%', palette),
              _infoChip('Remb.', '${item.remboursement}%', palette),
              if (item.type.isNotEmpty) _infoChip('Type', item.type, palette),
              _infoChip('Statut', item.statut, palette),
              if (item.conditionnement.isNotEmpty) _infoChip('Cond.', item.conditionnement, palette),
              if (item.localisation.isNotEmpty) _infoChip('Localisation', item.localisation, palette),
              if (item.sku.isNotEmpty) _infoChip('SKU', item.sku, palette),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stockRow('Officine', item.qtyOfficine, isRupture || isAlerte, palette),
                    _stockRow('Réserve', item.qtyReserve, isRupture || isAlerte, palette),
                    _stockRow('Total', total, isRupture || isAlerte, palette, bold: true),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Seuil mini : ${item.seuil}', style: TextStyle(color: palette.subText, fontSize: 14)),
                  Text(
                    'Péremption : ${item.peremption}',
                    style: TextStyle(
                      color: isExpiring ? Colors.red : palette.subText,
                      fontWeight: isExpiring ? FontWeight.bold : null,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.valeur.toStringAsFixed(0)} FCFA',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: accent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              if (item.ordonnance)
                Chip(
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  label: const Text('Ordonnance requise'),
                  avatar: const Icon(Icons.receipt_long, size: 18, color: Colors.orange),
                  labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              if (item.controle)
                Chip(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  label: const Text('Contrôlé'),
                  avatar: const Icon(Icons.verified_user, size: 18, color: Colors.red),
                  labelStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: () => _openProductForm(existing: item),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: TextButton.styleFrom(foregroundColor: accent),
                ),
                TextButton.icon(
                  onPressed: () => _showMovementsDialog(item),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Mouvements'),
                  style: TextButton.styleFrom(foregroundColor: palette.subText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockRow(String label, int qty, bool alert, ThemeColors palette, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: palette.subText, fontSize: 14))),
          Text(
            qty.toString(),
            style: TextStyle(
              fontSize: bold ? 20 : 17,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: alert ? (qty == 0 ? Colors.red : Colors.orange) : palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12.5, color: palette.text.withOpacity(0.9), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  void _showMovementsDialog(StockItem item) async {
    List<StockMovement> movements = [];
    final palette = ThemeColors.from(context);
    try {
      movements = await ProductService.instance.fetchMovementsForProduct(item.id);
      // Ensure the product name is set on each movement
      movements = movements
          .map((m) => StockMovement(
                id: m.id,
                productName: item.name,
                type: m.type,
                quantity: m.quantity,
                quantityBefore: m.quantityBefore,
                quantityAfter: m.quantityAfter,
                reason: m.reason,
                date: m.date,
                reference: m.reference,
                notes: m.notes,
                user: m.user,
              ))
          .toList();
    } catch (e, st) {
      // ignore: avoid_print
      print('Failed to load movements for product ${item.id}: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les mouvements pour ce produit')),
        );
      }
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: palette.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            constraints: BoxConstraints(maxWidth: 900, maxHeight: MediaQuery.of(context).size.height * 0.85),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mouvements de stock',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text),
                        ),
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 14, color: palette.subText),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Stats
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _movementStat('Total entrées', movements.where((m) => m.type == 'entree').fold<int>(0, (sum, m) => sum + m.quantity).toString(), const Color(0xFF10B981), palette),
                    _movementStat('Total sorties', movements.where((m) => m.type == 'sortie').fold<int>(0, (sum, m) => sum + m.quantity).toString(), const Color(0xFFEF4444), palette),
                    _movementStat('Ajustements', movements.where((m) => m.type == 'ajustement').length.toString(), const Color(0xFFF59E0B), palette),
                  ],
                ),
                const SizedBox(height: 18),
                // Movements List
                if (movements.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: palette.subText.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text('Aucun mouvement enregistré', style: TextStyle(color: palette.subText)),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: movements.map((movement) => _movementTile(movement, palette)).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _movementStat(String label, String value, Color color, ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: palette.subText)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _movementTile(StockMovement movement, ThemeColors palette) {
    final isPositive = movement.type == 'entree' || (movement.type == 'ajustement' && movement.quantity > 0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.displayType,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: movement.typeColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movement.displayReason,
                      style: TextStyle(fontSize: 13, color: palette.subText),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : '-'}${movement.quantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movement.quantityBefore} → ${movement.quantityAfter}',
                    style: TextStyle(fontSize: 12, color: palette.subText),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: palette.subText),
              const SizedBox(width: 6),
              Text(movement.formattedDate, style: TextStyle(fontSize: 12, color: palette.subText)),
              const SizedBox(width: 16),
              Icon(Icons.person, size: 14, color: palette.subText),
              const SizedBox(width: 6),
              Text(movement.user, style: TextStyle(fontSize: 12, color: palette.subText)),
              if (movement.reference != null) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: movement.typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    movement.reference!,
                    style: TextStyle(fontSize: 11, color: movement.typeColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          if (movement.notes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.isDark ? Colors.white.withOpacity(0.03) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!),
              ),
              child: Text(
                movement.notes!,
                style: TextStyle(fontSize: 12, color: palette.subText, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarginResult {
  final double percent;
  final double value;
  const _MarginResult({required this.percent, required this.value});
}

class StockItem {
  final String id;
  final String name,
      code,
      dci,
      dosage,
      family,
      lab,
      form,
      peremption,
      lot,
      statut,
      type,
      sku,
      localisation,
      fournisseur,
      description,
      conditionnement,
      notice,
      image;
  final int qtyOfficine,
      qtyReserve,
      seuil,
      seuilMax,
      prixAchat,
      prixVente,
      tva,
      remboursement,
      valeur;
  final bool ordonnance, controle;

  const StockItem({
    required this.id,
    required this.name,
    required this.code,
    required this.dci,
    required this.dosage,
    required this.family,
    required this.lab,
    required this.form,
    required this.qtyOfficine,
    required this.qtyReserve,
    required this.seuil,
    required this.seuilMax,
    required this.prixAchat,
    required this.prixVente,
    required this.tva,
    required this.remboursement,
    required this.statut,
    required this.type,
    required this.sku,
    required this.localisation,
    required this.fournisseur,
    required this.ordonnance,
    required this.controle,
    required this.description,
    required this.conditionnement,
    required this.notice,
    required this.image,
    required this.peremption,
    required this.lot,
    required this.valeur,
  });
}
