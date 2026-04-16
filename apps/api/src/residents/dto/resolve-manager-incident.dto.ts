import { IsUUID } from 'class-validator';

export class ResolveManagerIncidentDto {
  @IsUUID()
  shiftId!: string;
}
