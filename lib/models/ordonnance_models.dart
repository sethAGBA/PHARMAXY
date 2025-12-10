enum InteractionLevel { none, warning, danger }

class Patient {
  final String name;
  final String nir;
  final String mutuelle;

  const Patient({
    required this.name,
    required this.nir,
    required this.mutuelle,
  });
}

class PrescribedDrug {
  final String name;
  final String dosage;
  final int price;
  final bool generic;
  final InteractionLevel interaction;

  const PrescribedDrug({
    required this.name,
    required this.dosage,
    required this.price,
    required this.generic,
    required this.interaction,
  });
}
