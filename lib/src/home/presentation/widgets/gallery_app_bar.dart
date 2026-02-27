import 'package:flutter/material.dart';
import 'package:milestone/src/home/presentation/widgets/palette.dart';

class GalleryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GalleryAppBar(this.title, {super.key, this.source, this.actions});
  final List<String> title;
  final String? source;
  final List<Widget>? actions;

  @override
  AppBar build(BuildContext context) => AppBar(
        leading: title.length == 1
            ? null
            : GalleryAppBarButton(Icons.arrow_back_ios, () {
                Navigator.pushReplacementNamed(context, '/');
              }),
        title: SizedBox(
          height: kToolbarHeight,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Row(
              children: [
                for (var i = 0; i < title.length; i++) ...[
                  if (i != 0)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_right,
                        color: palette.foreground.withValues(alpha: 0.5),
                      ),
                    ),
                  Text(
                    title[i],
                  ),
                ],
              ],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          if (actions != null) ...actions!,
          if (source != null)
            GalleryAppBarButton(
              Icons.description,
              () {
                // launchUrl(Uri.parse(source!));
              },
              tooltip: 'Source code',
            ),
          const Padding(padding: EdgeInsets.only(right: 8)),
        ],
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class GalleryAppBarButton extends StatelessWidget {
  const GalleryAppBarButton(this.icon, this.onTap, {super.key, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget result = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 56),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: 8,
        ),
        child: Material(
          color: palette.primary,
          borderRadius: BorderRadius.circular(2),
          child: InkWell(
            onTap: onTap,
            child: Icon(
              icon,
              size: 16,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      result = Tooltip(
        message: tooltip,
        child: result,
      );
    }

    return result;
  }
}
