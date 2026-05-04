// CSV / XLSX export.

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../models/daily_summary.dart';
import '../models/payslip.dart';
import '../models/punch.dart';

class ExportService {
  static final DateFormat _ts = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _time = DateFormat('HH:mm');

  Future<File> writePunchesCsv(String path, List<Punch> punches) async {
    final rows = <List<Object?>>[
      <Object?>['user_id', 'timestamp', 'raw_status', 'raw_punch'],
      ...punches.map((p) => <Object?>[
            p.userId,
            _ts.format(p.timestamp),
            p.rawStatus,
            p.rawPunch,
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(csv, encoding: utf8);
    return file;
  }

  Future<File> writeDailyCsv(String path, List<DailySummary> daily) async {
    final rows = <List<Object?>>[
      <Object?>[
        'user_id',
        'date',
        'check_in',
        'check_out',
        'worked_hours',
        'status',
        'notes',
      ],
      ...daily.map((d) => <Object?>[
            d.userId,
            _date.format(d.date),
            d.checkIn != null ? _time.format(d.checkIn!) : '',
            d.checkOut != null ? _time.format(d.checkOut!) : '',
            (d.workedMinutes / 60).toStringAsFixed(2),
            d.status.wireValue,
            d.notes,
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(csv, encoding: utf8);
    return file;
  }

  /// Multi-sheet workbook: "Daily" + "Punches".
  Future<File> writeMonthlyXlsx(
    String path,
    DateTime month, {
    required List<DailySummary> daily,
    required List<Punch> punches,
  }) async {
    final wb = Excel.createExcel();
    wb.delete('Sheet1');

    final dailySheet = wb['Daily'];
    dailySheet.appendRow(<CellValue?>[
      TextCellValue('user_id'),
      TextCellValue('date'),
      TextCellValue('check_in'),
      TextCellValue('check_out'),
      TextCellValue('worked_hours'),
      TextCellValue('status'),
      TextCellValue('notes'),
    ]);
    for (final d in daily) {
      dailySheet.appendRow(<CellValue?>[
        TextCellValue(d.userId),
        TextCellValue(_date.format(d.date)),
        TextCellValue(d.checkIn != null ? _time.format(d.checkIn!) : ''),
        TextCellValue(d.checkOut != null ? _time.format(d.checkOut!) : ''),
        DoubleCellValue(d.workedMinutes / 60),
        TextCellValue(d.status.wireValue),
        TextCellValue(d.notes),
      ]);
    }

    final pSheet = wb['Punches'];
    pSheet.appendRow(<CellValue?>[
      TextCellValue('user_id'),
      TextCellValue('timestamp'),
      TextCellValue('raw_status'),
      TextCellValue('raw_punch'),
    ]);
    for (final pn in punches) {
      pSheet.appendRow(<CellValue?>[
        TextCellValue(pn.userId),
        TextCellValue(_ts.format(pn.timestamp)),
        IntCellValue(pn.rawStatus),
        IntCellValue(pn.rawPunch),
      ]);
    }

    final bytes = wb.encode();
    if (bytes == null) {
      throw Exception('Failed to encode XLSX');
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  String suggestedFilename(DateTime month, String ext) {
    final stamp = DateFormat('yyyy-MM').format(month);
    return p.join('attendance_$stamp.$ext');
  }

  /// Single-sheet workbook for one payslip. Header rows describe the
  /// employee/period; line items break out compensation; a totals
  /// block resolves to net payable.
  Future<File> writePayslipXlsx(
    String path, {
    required Payslip payslip,
    required String employeeName,
    String? employeeCode,
  }) async {
    final wb = Excel.createExcel();
    wb.delete('Sheet1');
    final sheet = wb['Payslip'];

    void kv(String k, CellValue v) {
      sheet.appendRow(<CellValue?>[TextCellValue(k), v]);
    }

    sheet.appendRow(<CellValue?>[TextCellValue('Payslip')]);
    kv('Employee', TextCellValue(employeeName));
    if (employeeCode != null && employeeCode.isNotEmpty) {
      kv('Employee ID', TextCellValue(employeeCode));
    }
    kv('Period start', TextCellValue(_date.format(payslip.periodStart)));
    kv('Period end', TextCellValue(_date.format(payslip.periodEnd)));
    kv('Currency', TextCellValue(payslip.currency));
    kv('Status', TextCellValue(payslip.status.name));
    kv('Issued', TextCellValue(_date.format(payslip.createdAt)));
    if (payslip.processedAt != null) {
      kv('Processed', TextCellValue(_ts.format(payslip.processedAt!)));
    }
    if (payslip.disbursedAt != null) {
      kv('Disbursed', TextCellValue(_ts.format(payslip.disbursedAt!)));
    }
    sheet.appendRow(<CellValue?>[]);

    sheet.appendRow(<CellValue?>[
      TextCellValue('Attendance'),
      TextCellValue('Days'),
    ]);
    sheet.appendRow(
        <CellValue?>[TextCellValue('Working'), IntCellValue(payslip.workingDays)]);
    sheet.appendRow(
        <CellValue?>[TextCellValue('Present'), IntCellValue(payslip.presentDays)]);
    sheet.appendRow(
        <CellValue?>[TextCellValue('Late'), IntCellValue(payslip.lateDays)]);
    sheet.appendRow(
        <CellValue?>[TextCellValue('Leave'), IntCellValue(payslip.leaveDays)]);
    sheet.appendRow(
        <CellValue?>[TextCellValue('Absent'), IntCellValue(payslip.absentDays)]);
    sheet.appendRow(<CellValue?>[]);

    sheet.appendRow(<CellValue?>[
      TextCellValue('Line item'),
      TextCellValue('Amount (${payslip.currency})'),
    ]);
    sheet.appendRow(<CellValue?>[
      TextCellValue('Basic'),
      DoubleCellValue(payslip.basic),
    ]);
    sheet.appendRow(<CellValue?>[
      TextCellValue('Total allowances'),
      DoubleCellValue(payslip.totalAllowances),
    ]);
    sheet.appendRow(<CellValue?>[
      TextCellValue('Gross'),
      DoubleCellValue(payslip.gross),
    ]);
    sheet.appendRow(<CellValue?>[
      TextCellValue('Total deductions'),
      DoubleCellValue(-payslip.totalDeductions),
    ]);
    sheet.appendRow(<CellValue?>[
      TextCellValue('Attendance deduction'),
      DoubleCellValue(-payslip.attendanceDeduction),
    ]);
    sheet.appendRow(<CellValue?>[
      TextCellValue('Net payable'),
      DoubleCellValue(payslip.netPayable),
    ]);

    if (payslip.notes != null && payslip.notes!.trim().isNotEmpty) {
      sheet.appendRow(<CellValue?>[]);
      sheet.appendRow(<CellValue?>[TextCellValue('Notes')]);
      sheet.appendRow(<CellValue?>[TextCellValue(payslip.notes!)]);
    }

    final bytes = wb.encode();
    if (bytes == null) {
      throw Exception('Failed to encode XLSX');
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  String suggestedPayslipFilename(
    DateTime periodStart,
    String employeeName,
  ) {
    final safe = employeeName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final stamp = DateFormat('yyyy-MM').format(periodStart);
    return 'payslip_${safe}_$stamp.xlsx';
  }

  /// Generic CSV writer for the per-report runner. [headers] becomes
  /// the first row; [rows] follows. Each row's length should match
  /// [headers].
  Future<File> writeRowsCsv(
    String path, {
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final all = <List<Object?>>[
      <Object?>[...headers],
      for (final r in rows) <Object?>[...r],
    ];
    final csv = const ListToCsvConverter().convert(all);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(csv, encoding: utf8);
    return file;
  }
}
