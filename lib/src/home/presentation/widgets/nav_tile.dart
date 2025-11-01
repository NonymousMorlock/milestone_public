import 'package:flutter/material.dart';

class NavTile extends StatelessWidget {
  const NavTile({
    required this.icon,
    required this.title,
    super.key,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          tileColor: Colors.black.withValues(alpha: .08),
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          onTap: onTap,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_right,
            color: Colors.white,
          ),
        ),
        Divider(
          color: Colors.grey.withValues(alpha: .5),
          height: 0,
          thickness: 1,
        ),
      ],
    );
  }
}
