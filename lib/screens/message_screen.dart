import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';

class MessageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('MESSAGES', style: GoogleFonts.righteous(color: AppTheme.peach)),
        actions: [
          IconButton(icon: Icon(Icons.edit_note, color: AppTheme.peach), onPressed: () {}),
        ],
      ),
      body: DynamicBackground(
        child: SafeArea(
          child: ListView.separated(
            itemCount: 8,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.white10),
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.peach.withOpacity(0.5)),
                  ),
                  child: CircleAvatar(
                    backgroundColor: AppTheme.darkPurple,
                    child: Text('U${index + 1}', style: GoogleFonts.spaceMono(color: AppTheme.peach, fontWeight: FontWeight.bold)),
                  ),
                ),
                title: Text('USER_${index + 1}', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('ENCRYPTED_TRANSMISSION_RECEIVED...', style: GoogleFonts.spaceMono(color: Colors.white60, fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('12:30 PM', style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.white38)),
                    if (index < 2)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.peach, borderRadius: BorderRadius.circular(10)),
                        child: Text('NEW', style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                onTap: () {},
              );
            },
          ),
        ),
      ),
    );
  }
}

