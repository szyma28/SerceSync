import { IsEnum } from 'class-validator';
import { MedicationDoseStatus } from '@prisma/client';
import { RecordDoseOutcomeDto } from './record-dose-outcome.dto';

export class UpdateDoseStatusDto extends RecordDoseOutcomeDto {
  @IsEnum(MedicationDoseStatus)
  status!: MedicationDoseStatus;
}
