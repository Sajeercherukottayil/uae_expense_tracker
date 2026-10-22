import 'package:intl/intl.dart';

final _aed = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);

String aed(double value) => _aed.format(value);

final dayFormat = DateFormat('EEE, d MMM yyyy');
final monthFormat = DateFormat('MMMM yyyy');
