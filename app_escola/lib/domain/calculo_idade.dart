/// Idade em anos completos (regra simples: aniversário já ocorrido no ano de referência).
/// Alinhado à necessidade do escopo (idade a partir da data de nascimento do aluno).
int? idadeEmAnosCompleta(DateTime? nascimento, DateTime referencia) {
  if (nascimento == null) return null;
  var idade = referencia.year - nascimento.year;
  final aniversarioEsteAno = DateTime(
    referencia.year,
    nascimento.month,
    nascimento.day,
  );
  if (referencia.isBefore(aniversarioEsteAno)) {
    idade--;
  }
  return idade < 0 ? null : idade;
}
