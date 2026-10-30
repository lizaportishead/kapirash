bool isStandalone() => false;

void onAppInstalled(void Function() cb) {}

/// На телефоне-приложении баннер «добавить на экран» не нужен.
String? installPlatform() => null;

/// Нижний отступ под индикатор «домой» на iPhone в PWA; в нативном приложении его даёт SafeArea.
double webSafeBottom() => 0;
