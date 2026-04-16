import { IsUUID } from 'class-validator';

export class AcknowledgeManagerIncidentDto {
  @IsUUID()
  shiftId!: string;
}
