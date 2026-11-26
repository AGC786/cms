import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import '../models/mock_data.dart';

/// Generic screen used for simpler list/info-style pages (Notice Board,
/// Holidays, About Us, etc). Real projects would replace the body with a
/// screen-specific widget / API-backed list.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final bool blueHeader;
  const PlaceholderScreen({super.key, required this.title, this.blueHeader = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gradientAppBar(context, title, blue: blueHeader),
      body: Column(
        children: [
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildBody())),
          const FooterUrlBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (title) {
      case 'Notice Board':
        return Column(
          children: adminNotices
              .map((n) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC21F75), width: 1.5), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: const BoxDecoration(color: Color(0xFF8C1848)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(n.date, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              Text(n.title, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(padding: const EdgeInsets.all(11), child: Text(n.body, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ))
              .toList(),
        );
      case 'Holidays':
        return Column(
          children: holidays
              .map((h) => Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC21F75), width: 1.5), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFF8C1848), borderRadius: BorderRadius.circular(8)),
                          child: Text(h.date, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(h.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ))
              .toList(),
        );
      case 'About Us':
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About AIT', style: TextStyle(color: Color(0xFF8C1848), fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 6),
            Text(
              'The Aligarh Institute of Technology (AIT), a Polytechnic Institute, established in 1989, offers the Diploma of Associate Engineering (DAE) recognized by the Sindh Board of Technical Education.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('Mission', style: TextStyle(color: Color(0xFF8C1848), fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 6),
            Text(
              'To meet growing challenges of the new millennium by providing required skills in advanced technologies.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        );
      default:
        return const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Text('This screen mirrors the HTML prototype pattern — wire up\nyour real data/API here.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        );
    }
  }
}
