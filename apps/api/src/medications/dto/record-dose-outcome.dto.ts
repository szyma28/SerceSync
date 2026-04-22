import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class RecordDoseOutcomeDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  doseGiven?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  doseUnit?: string;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;

  @IsOptional()
  @IsString()
  witnessUserId?: string;
}
