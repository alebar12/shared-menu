import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/menu_service.dart';

class ShareMenuView extends StatefulWidget {
  const ShareMenuView({
    super.key,
  });

  @override
  State<ShareMenuView> createState() => _ShareMenuViewState();
}

class _ShareMenuViewState extends State<ShareMenuView> {
  late final MenuService _menuService;
  late Future<String> menuId;

  @override
  void initState() {
    super.initState();
    _menuService = context.read<MenuService>();
    menuId = _menuService.currentMenuId();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.menuActionShare),
      ),
      body: FutureBuilder<String>(
        future: menuId,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.errorLoadingMenuId),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        menuId = _menuService.currentMenuId();
                      });
                    },
                    child: Text(l10n.labelRetry),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.shareMenuInstruction,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: QrImageView(
                        data: snapshot.data!,
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
