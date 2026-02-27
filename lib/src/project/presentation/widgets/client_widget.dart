import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/core/res/styles/colours.dart';

class ClientWidget extends StatefulWidget {
  const ClientWidget({required this.clientName, super.key});
  final String clientName;

  @override
  State<ClientWidget> createState() => _ClientWidgetState();
}

class _ClientWidgetState extends State<ClientWidget> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF3A2E39),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Container(
                  height: double.maxFinite,
                  width: double.maxFinite,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colours.lightThemeSecondaryColour,
                        Colours.lightThemeYellowColour,
                        Colours.lightThemePrimaryColour,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.clientName.initials,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: expanded ? 24 : 16,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  expanded = !expanded;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: expanded ? 84 : 48,
                height: expanded ? 84 : 48,
                curve: Curves.ease,
                margin: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
