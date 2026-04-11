import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale fixo da aplicação (calendário Material e [DateFormat]).
const Locale kAppLocale = Locale('pt', 'BR');

/// Data curta brasileira: 10/04/2026
final DateFormat kAppDateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

/// Competência em títulos: "abril de 2026"
final DateFormat kAppMesAnoLongo = DateFormat.yMMMM('pt_BR');

/// Mês/ano numérico: 04/2026
final DateFormat kAppMesAnoCurto = DateFormat('MM/yyyy', 'pt_BR');

/// Nome do mês (1–12): "janeiro", "fevereiro", …
String nomeMesPt(int month) =>
    DateFormat.MMMM('pt_BR').format(DateTime(2000, month, 1));
