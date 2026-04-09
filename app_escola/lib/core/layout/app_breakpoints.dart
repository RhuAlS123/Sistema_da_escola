/// Larguras de referência para layout responsivo (PC vs mobile).
/// Valores convencionais; não há número “oficial” na especificação do cliente.
///
/// O shell principal usa [isMobileWidth] para alternar barra inferior / trilho lateral
/// (`app_main_shell.dart`). Em `app.dart`, o [MaterialApp] limita escala de texto
/// com [minTextScale] / [maxTextScale].
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static const double minTextScale = 0.9;
  static const double maxTextScale = 1.2;

  static bool isMobileWidth(double width) => width < mobileMaxWidth;
  static bool isTabletWidth(double width) =>
      width >= mobileMaxWidth && width < tabletMaxWidth;
  static bool isDesktopWidth(double width) => width >= tabletMaxWidth;
}
