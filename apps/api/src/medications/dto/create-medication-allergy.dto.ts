import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateMedicationAllergyDto {
  @IsString()
  @MinLength(2)
  @MaxLength(160)
  substance!: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  reaction?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  severity?: string;
}
