import 'package:flutter/material.dart';

class MessageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        actions: [
          IconButton(icon: Icon(Icons.edit_note), onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        itemCount: 8,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: Text('U${index + 1}', style: TextStyle(color: Colors.blueAccent)),
            ),
            title: Text('User ${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Hey, did you see the latest post?'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('12:30 PM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                if (index < 2)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    child: Text('1', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}
