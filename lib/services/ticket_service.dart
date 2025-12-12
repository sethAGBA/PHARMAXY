import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/sale_models.dart';

class TicketService {
  TicketService._();

  static final TicketService instance = TicketService._();

  String _buildVerificationCode(String saleId, double total, DateTime now) {
    final seed = '$saleId|$total|${now.microsecondsSinceEpoch}';
    final checksum = seed.codeUnits.fold<int>(
      0,
      (acc, unit) => (acc + unit) & 0xFFFF,
    );
    return checksum.toRadixString(16).padLeft(4, '0').toUpperCase();
  }

  Future<Uint8List> generateReceipt({
    required String saleId,
    required String client,
    required double total,
    required String paymentMethod,
    required List<CartItem> items,
    String? vendor,
    String? logoPath,
    String currency = 'FCFA',
    String title = 'Ticket de vente',
    String? pharmacyName,
    String? pharmacyAddress,
    String? pharmacyPhone,
    String? pharmacyEmail,
    String? pharmacyOrderNumber,
    String? pharmacyWebsite,
    String? pharmacyHours,
    String? emergencyContact,
    String? fiscalId,
    String? taxDetails,
    String? returnPolicy,
    String? healthAdvice,
    String? loyaltyMessage,
    String? ticketLink,
    String footerMessage = 'Merci de votre confiance. Prompt rétablissement !',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final header = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final sub = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final tableStyle = sub.copyWith(fontSize: 9);
    final currencyFormatter = NumberFormat('#,##0', 'fr_FR');
    final verificationCode = _buildVerificationCode(saleId, total, now);
    final resolvedTicketLink = _resolveTicketLink(
      ticketLink: ticketLink,
      saleId: saleId,
    );
    final qrData = (resolvedTicketLink != null && resolvedTicketLink.isNotEmpty)
        ? resolvedTicketLink
        : 'SALE:$saleId;TOTAL:${currencyFormatter.format(total)} $currency;CLIENT:${client.isNotEmpty ? client : 'Gen'};DATE:$dateStr;VERIF:$verificationCode';

    final logo = await _loadLogo(logoPath);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null) pw.Center(child: pw.Image(logo, height: 50)),
              pw.SizedBox(height: logo == null ? 0 : 8),
              pw.Text(title, style: header),
              pw.SizedBox(height: 4),
              if (pharmacyName != null && pharmacyName.isNotEmpty)
                pw.Text(pharmacyName, style: header.copyWith(fontSize: 12)),
              if (pharmacyAddress != null && pharmacyAddress.isNotEmpty)
                pw.Text(pharmacyAddress, style: sub),
              if (pharmacyPhone != null && pharmacyPhone.isNotEmpty)
                pw.Text('Tél: $pharmacyPhone', style: sub),
              if (pharmacyEmail != null && pharmacyEmail.isNotEmpty)
                pw.Text('Email: $pharmacyEmail', style: sub),
              if (pharmacyWebsite != null && pharmacyWebsite.isNotEmpty)
                pw.Text('Site: $pharmacyWebsite', style: sub),
              if (pharmacyOrderNumber != null && pharmacyOrderNumber.isNotEmpty)
                pw.Text('Ordre: $pharmacyOrderNumber', style: sub),
              pw.Text('Ticket #$saleId', style: sub),
              pw.Text('Date: $dateStr', style: sub),
              pw.Divider(),
              if (items.isNotEmpty)
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.6),
                  },
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(
                      width: .2,
                      color: PdfColors.grey,
                    ),
                  ),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            'Produit',
                            style: tableStyle.copyWith(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            'Qté',
                            style: tableStyle.copyWith(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            'Total ($currency)',
                            style: tableStyle.copyWith(
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final lotsText =
                          (item.lots != null && item.lots!.isNotEmpty)
                          ? ' (Lot: ${item.lots!.entries.map((e) => '${e.key} x${e.value}').join(', ')})'
                          : '';
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              '${item.name}$lotsText',
                              style: tableStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              'x${item.quantity}',
                              style: tableStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              currencyFormatter.format(
                                item.price * item.quantity,
                              ),
                              style: tableStyle,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                )
              else
                pw.Text('Aucun détail de vente', style: sub),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Client', style: sub),
                  pw.Text(client.isNotEmpty ? client : 'Générique', style: sub),
                ],
              ),
              if (vendor != null && vendor.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Vendeur', style: sub),
                    pw.Text(vendor, style: sub),
                  ],
                ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Méthode', style: sub),
                  pw.Text(paymentMethod, style: sub),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: header),
                  pw.Text(
                    '${currencyFormatter.format(total)} $currency',
                    style: header,
                  ),
                ],
              ),
              if (fiscalId != null && fiscalId.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('IFU', style: sub),
                    pw.Text(fiscalId, style: sub),
                  ],
                ),
              if (taxDetails != null && taxDetails.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text('TVA/Taxes: $taxDetails', style: sub),
                ),
              if (pharmacyHours != null && pharmacyHours.isNotEmpty)
                pw.Text('Horaires: $pharmacyHours', style: sub),
              if (emergencyContact != null && emergencyContact.isNotEmpty)
                pw.Text('Urgences: $emergencyContact', style: sub),
              if (healthAdvice != null && healthAdvice.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text('Conseil santé: $healthAdvice', style: sub),
                ),
              if (returnPolicy != null && returnPolicy.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text('Retour/échange: $returnPolicy', style: sub),
                ),
              if (loyaltyMessage != null && loyaltyMessage.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(loyaltyMessage, style: sub),
                ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text('Code vérif: $verificationCode', style: sub),
              ),
              if (resolvedTicketLink != null && resolvedTicketLink.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'Ticket en ligne: $resolvedTicketLink',
                    style: sub,
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 0.3,
                        ),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: qrData,
                        width: 90,
                        height: 90,
                        drawText: false,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Scannez pour retrouver le ticket',
                      style: sub.copyWith(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  footerMessage,
                  style: sub.copyWith(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  String? _resolveTicketLink({required String saleId, String? ticketLink}) {
    final raw = ticketLink?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('{id}')) {
      return raw.replaceAll('{id}', saleId);
    }
    if (raw.contains('{saleId}')) {
      return raw.replaceAll('{saleId}', saleId);
    }
    return raw;
  }

  Future<pw.ImageProvider?> _loadLogo(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return pw.MemoryImage(bytes);
  }
}
