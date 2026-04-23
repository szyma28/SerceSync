export type CsvCell = Date | string | number | boolean | null | undefined;

export function neutralizeCsvFormula(value: string) {
  if (!value) {
    return value;
  }

  return /^[=+\-@]/.test(value) ? `'${value}` : value;
}

export function toSafeCsvCell(value: CsvCell) {
  if (value == null) {
    return '';
  }

  const rendered = value instanceof Date ? value.toISOString() : String(value);
  const normalized = neutralizeCsvFormula(rendered);
  if (/[",\n]/.test(normalized)) {
    return `"${normalized.replace(/"/g, '""')}"`;
  }

  return normalized;
}

export function buildCsvDocument(
  headers: readonly string[],
  rows: ReadonlyArray<ReadonlyArray<CsvCell>>,
) {
  const headerRow = headers.map((header) => toSafeCsvCell(header)).join(',');
  const bodyRows = rows.map((row) =>
    row.map((cell) => toSafeCsvCell(cell)).join(','),
  );
  return [headerRow, ...bodyRows].join('\n');
}
