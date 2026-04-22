import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CompleteMedicationReconciliationDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  discrepancySummary?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  controlledDrugCheckSummary?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
