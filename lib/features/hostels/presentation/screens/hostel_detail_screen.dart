import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../../models/hostel.dart';

class HostelDetailScreen extends StatefulWidget {
  final Hostel hostel;
  const HostelDetailScreen({super.key, required this.hostel});

  @override
  State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  int _page = 0;
  Hostel get hostel => widget.hostel;

  List<String> get _images {
    final images = <String>[...hostel.imageUrls];
    if (hostel.imageUrl.isNotEmpty && !images.contains(hostel.imageUrl)) images.insert(0, hostel.imageUrl);
    return images;
  }

  Future<void> _openWebsite() async {
    var value = hostel.website.trim();
    if (value.isEmpty) return;
    if (!value.startsWith('http://') && !value.startsWith('https://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Website could not be opened.')));
    }
  }

  Future<void> _copyPhone() async {
    await Clipboard.setData(ClipboardData(text: hostel.phone));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number copied')));
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Hostel Details')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(hostel.name, style: const TextStyle(color: AppColors.darkGreen, fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          _gallery(images),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _title('Location'),
              _card([
                if (hostel.address.isNotEmpty) _row(Icons.location_on_outlined, 'Address', hostel.address),
                if (hostel.area.isNotEmpty || hostel.city.isNotEmpty) _row(Icons.place_outlined, 'Area', [hostel.area, hostel.city].where((e) => e.isNotEmpty).join(', ')),
                if (hostel.distance.isNotEmpty) _row(Icons.near_me_outlined, 'Distance', hostel.distance),
              ]),
              _title('Complete Details'),
              _card([
                _row(Icons.apartment_outlined, 'Hostel Type', hostel.type),
                _row(Icons.people_outline, 'For', hostel.gender),
                if (hostel.roomType.isNotEmpty) _row(Icons.bed_outlined, 'Room Type', hostel.roomType),
                if (hostel.availability.isNotEmpty) _row(Icons.event_available_outlined, 'Availability', hostel.availability),
                if (hostel.price.isNotEmpty) _row(Icons.payments_outlined, 'Monthly Rent', hostel.price),
                if (hostel.securityFee.isNotEmpty) _row(Icons.account_balance_wallet_outlined, 'Security Fee', hostel.securityFee),
                _row(Icons.ac_unit_outlined, 'Air Conditioning', hostel.ac ? 'Available' : 'Not available'),
                if (hostel.meals.isNotEmpty) _row(Icons.restaurant_outlined, 'Meals / Mess', hostel.meals),
              ]),
              if (hostel.facilities.isNotEmpty) ...[
                _title('Facilities'),
                _card([Wrap(spacing: 8, runSpacing: 8, children: hostel.facilities.map(_facility).toList())]),
              ],
              if (hostel.description.isNotEmpty) ...[
                _title('About Hostel'),
                _card([Text(hostel.description, style: const TextStyle(color: AppColors.mutedText, height: 1.45, fontSize: 14))]),
              ],
              if (hostel.ownerName.isNotEmpty && !hostel.isDemo) ...[
                _title('Listed By'),
                _card([_row(Icons.person_outline, 'Owner', hostel.ownerName)]),
              ],
              if (hostel.phone.isNotEmpty || hostel.website.isNotEmpty) ...[
                _title('Contact'),
                _card([
                  if (hostel.phone.isNotEmpty) _button(Icons.phone_outlined, hostel.phone, _copyPhone),
                  if (hostel.phone.isNotEmpty && hostel.website.isNotEmpty) const SizedBox(height: 8),
                  if (hostel.website.isNotEmpty) _button(Icons.language_outlined, hostel.website, _openWebsite),
                ]),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _gallery(List<String> images) => Column(children: [
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 235,
      decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: images.isEmpty
          ? const Center(child: Icon(Icons.hotel_rounded, color: AppColors.primaryGreen, size: 72))
          : PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Image.network(
                images[i], fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.primaryGreen, size: 48)),
              ),
            ),
    ),
    if (images.length > 1) Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(images.length, (i) => Container(
        width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: i == _page ? AppColors.primaryGreen : AppColors.divider, shape: BoxShape.circle),
      ))),
    ),
  ]);

  Widget _title(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    child: Text(title, style: const TextStyle(color: AppColors.darkGreen, fontSize: 17, fontWeight: FontWeight.w700)),
  );

  Widget _card(List<Widget> children) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primaryGreen, size: 20),
      const SizedBox(width: 11),
      Expanded(child: RichText(text: TextSpan(children: [
        TextSpan(text: '$label\n', style: const TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w600)),
        TextSpan(text: value, style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, height: 1.25)),
      ]))),
    ]),
  );

  Widget _facility(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(10)),
    child: Text(value, style: const TextStyle(color: AppColors.darkGreen, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _button(IconData icon, String label, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryGreen, side: const BorderSide(color: AppColors.divider), padding: const EdgeInsets.symmetric(vertical: 13)),
      icon: Icon(icon),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
});
