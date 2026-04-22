import {
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { MedicationStockTransactionType } from '@prisma/client';

export class CreateMedicationStockTransactionDto {
  @IsEnum(MedicationStockTransactionType)
  transactionType!: MedicationStockTransactionType;

  @IsString()
  @MinLength(1)
  @MaxLength(120)
  quantity!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(40)
  quantityUnit!: string;

  @IsOptional()
  @IsString()
  witnessUserId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
