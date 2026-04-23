import {
  buildCsvDocument,
  neutralizeCsvFormula,
  toSafeCsvCell,
} from './csv';

describe('CSV safety helpers', () => {
  it('neutralizes spreadsheet formulas before export', () => {
    expect(neutralizeCsvFormula('=2+2')).toBe("'=2+2");
    expect(neutralizeCsvFormula('+SUM(A1:A3)')).toBe("'+SUM(A1:A3)");
    expect(neutralizeCsvFormula('-cmd')).toBe("'-cmd");
    expect(neutralizeCsvFormula('@calc')).toBe("'@calc");
    expect(neutralizeCsvFormula('Routine note')).toBe('Routine note');
  });

  it('quotes and escapes CSV cells after formula neutralization', () => {
    expect(toSafeCsvCell('=resident note')).toBe("'=resident note");
    expect(toSafeCsvCell('He said, \"hello\"')).toBe('"He said, ""hello"""');
  });

  it('builds CSV documents with consistent escaping', () => {
    expect(
      buildCsvDocument(['Name', 'Note'], [
        ['Thea Green', '=follow-up needed'],
      ]),
    ).toBe("Name,Note\nThea Green,'=follow-up needed");
  });
});
