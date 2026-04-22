import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class UpdatePrnProtocolDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  indication?: string;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  whenToOffer?: string;

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  doseInstructions?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  minimumIntervalMinutes?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  maxDosePer24Hours?: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  expectedEffect?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  monitoringRequired?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  whenToEscalate?: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason!: string;
}
