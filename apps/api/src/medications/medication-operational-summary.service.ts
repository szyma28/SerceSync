import { Injectable, NotFoundException } from '@nestjs/common';
import {
  MedicationAdministrationEventType,
  MedicationDoseStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  buildResidentOperationalSummary,
  buildShiftOperationalSummary,
} from './medication-operational-summary.logic';
import type {
  MedicationResidentOperationalSummary,
  MedicationShiftOperationalSummary,
} from './medication-operational-summary.types';

@Injectable()
export class MedicationOperationalSummaryService {
  constructor(private readonly prisma: PrismaService) {}

  async buildResidentOperationalSummary(
    residentId: string,
    referenceTime = new Date(),
  ): Promise<MedicationResidentOperationalSummary> {
    const resident = await this.prisma.resident.findUnique({
      where: { id: residentId },
      select: {
        id: true,
        fullName: true,
        roomLabel: true,
        floorNumber: true,
        unitLabel: true,
      },
    });

    if (!resident) {
      throw new NotFoundException('Resident was not found.');
    }

    const activeShiftIds = await this.getActiveShiftIds();
    const [orders, doses, prnEvents, allergies, lastAdministrationEvent] =
      await Promise.all([
        this.prisma.medicationOrder.findMany({
          where: { residentId },
          include: {
            stockRecord: {
              select: {
                currentQuantity: true,
                quantityUnit: true,
                lastCheckedAt: true,
              },
            },
          },
          orderBy: [{ isPRN: 'asc' }, { medicationName: 'asc' }],
        }),
        activeShiftIds.length === 0
          ? Promise.resolve([])
          : this.prisma.medicationDoseInstance.findMany({
              where: {
                residentId,
                shiftId: { in: activeShiftIds },
                status: {
                  in: [
                    MedicationDoseStatus.DUE,
                    MedicationDoseStatus.OVERDUE,
                    MedicationDoseStatus.REFUSED,
                    MedicationDoseStatus.OMITTED,
                    MedicationDoseStatus.DELAYED,
                    MedicationDoseStatus.NOT_AVAILABLE,
                    MedicationDoseStatus.HELD,
                  ],
                },
              },
              select: {
                residentId: true,
                dueWindowStart: true,
                dueWindowEnd: true,
                status: true,
              },
            }),
        this.prisma.medicationAdministrationEvent.findMany({
          where: {
            residentId,
            eventType: {
              in: [
                MedicationAdministrationEventType.PRN_OFFERED,
                MedicationAdministrationEventType.PRN_ADMINISTERED,
                MedicationAdministrationEventType.PRN_REFUSED,
                MedicationAdministrationEventType.PRN_NOT_GIVEN,
              ],
            },
          },
          select: {
            residentId: true,
            eventType: true,
            recordedAt: true,
          },
          orderBy: { recordedAt: 'desc' },
          take: 50,
        }),
        this.prisma.medicationAllergyIntolerance.findMany({
          where: { residentId },
          select: {
            residentId: true,
            substance: true,
          },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.medicationAdministrationEvent.findFirst({
          where: { residentId },
          select: { recordedAt: true },
          orderBy: { recordedAt: 'desc' },
        }),
      ]);

    return buildResidentOperationalSummary(
      {
        resident,
        orders: orders.map((order) => ({
          id: order.id,
          residentId: order.residentId,
          medicationName: order.medicationName,
          isActive: order.isActive,
          isPRN: order.isPRN,
          isControlledDrug: order.isControlledDrug,
          requiresWitness: order.requiresWitness,
          stockRecord: order.stockRecord,
        })),
        doses,
        prnEvents,
        allergies,
        lastAdministrationAt: lastAdministrationEvent?.recordedAt ?? null,
        generatedAt: referenceTime,
      },
      referenceTime,
    );
  }

  async buildShiftOperationalSummary(
    shiftId: string,
    referenceTime = new Date(),
  ): Promise<MedicationShiftOperationalSummary> {
    const shift = await this.prisma.shift.findUnique({
      where: { id: shiftId },
      select: {
        id: true,
        name: true,
        status: true,
        startsAt: true,
        endsAt: true,
        floorNumber: true,
        unitLabel: true,
      },
    });

    if (!shift) {
      throw new NotFoundException('Shift was not found.');
    }

    const residents = await this.prisma.resident.findMany({
      where: {
        floorNumber: shift.floorNumber,
        isActive: true,
      },
      select: {
        id: true,
        fullName: true,
        roomLabel: true,
        floorNumber: true,
        unitLabel: true,
      },
      orderBy: [{ roomNumber: 'asc' }, { fullName: 'asc' }],
    });
    const residentIds = residents.map((resident) => resident.id);

    if (residentIds.length === 0) {
      return buildShiftOperationalSummary({
        shift,
        residents: [],
        generatedAt: referenceTime,
      });
    }

    const [orders, doses, prnEvents, allergies, lastAdministrationEvents] =
      await Promise.all([
        this.prisma.medicationOrder.findMany({
          where: {
            residentId: { in: residentIds },
          },
          include: {
            stockRecord: {
              select: {
                currentQuantity: true,
                quantityUnit: true,
                lastCheckedAt: true,
              },
            },
          },
          orderBy: [
            { residentId: 'asc' },
            { isPRN: 'asc' },
            { medicationName: 'asc' },
          ],
        }),
        this.prisma.medicationDoseInstance.findMany({
          where: {
            shiftId,
            residentId: { in: residentIds },
            status: {
              in: [
                MedicationDoseStatus.DUE,
                MedicationDoseStatus.OVERDUE,
                MedicationDoseStatus.REFUSED,
                MedicationDoseStatus.OMITTED,
                MedicationDoseStatus.DELAYED,
                MedicationDoseStatus.NOT_AVAILABLE,
                MedicationDoseStatus.HELD,
              ],
            },
          },
          select: {
            residentId: true,
            dueWindowStart: true,
            dueWindowEnd: true,
            status: true,
          },
        }),
        this.prisma.medicationAdministrationEvent.findMany({
          where: {
            residentId: { in: residentIds },
            shiftId,
            eventType: {
              in: [
                MedicationAdministrationEventType.PRN_OFFERED,
                MedicationAdministrationEventType.PRN_ADMINISTERED,
                MedicationAdministrationEventType.PRN_REFUSED,
                MedicationAdministrationEventType.PRN_NOT_GIVEN,
              ],
            },
          },
          select: {
            residentId: true,
            eventType: true,
            recordedAt: true,
          },
          orderBy: { recordedAt: 'desc' },
          take: 100,
        }),
        this.prisma.medicationAllergyIntolerance.findMany({
          where: {
            residentId: { in: residentIds },
          },
          select: {
            residentId: true,
            substance: true,
          },
          orderBy: [{ residentId: 'asc' }, { createdAt: 'desc' }],
        }),
        this.prisma.medicationAdministrationEvent.findMany({
          where: {
            residentId: { in: residentIds },
            shiftId,
          },
          select: {
            residentId: true,
            recordedAt: true,
          },
          orderBy: { recordedAt: 'desc' },
        }),
      ]);

    const lastAdministrationByResident = new Map<string, Date>();
    for (const event of lastAdministrationEvents) {
      if (!lastAdministrationByResident.has(event.residentId)) {
        lastAdministrationByResident.set(event.residentId, event.recordedAt);
      }
    }

    const residentSummaries = residents
      .map((resident) =>
        buildResidentOperationalSummary(
          {
            resident,
            orders: orders
              .filter((order) => order.residentId === resident.id)
              .map((order) => ({
                id: order.id,
                residentId: order.residentId,
                medicationName: order.medicationName,
                isActive: order.isActive,
                isPRN: order.isPRN,
                isControlledDrug: order.isControlledDrug,
                requiresWitness: order.requiresWitness,
                stockRecord: order.stockRecord,
              })),
            doses: doses.filter((dose) => dose.residentId === resident.id),
            prnEvents: prnEvents.filter(
              (event) => event.residentId === resident.id,
            ),
            allergies: allergies.filter(
              (entry) => entry.residentId === resident.id,
            ),
            lastAdministrationAt:
              lastAdministrationByResident.get(resident.id) ?? null,
            generatedAt: referenceTime,
          },
          referenceTime,
        ),
      )
      .filter((summary) => {
        return (
          summary.activeOrders.total > 0 ||
          summary.openDoses.due > 0 ||
          summary.openDoses.overdue > 0 ||
          summary.exceptions.total > 0 ||
          summary.prn.latestRecordedAt != null ||
          summary.allergies.total > 0 ||
          summary.stock.exceptionCount > 0
        );
      });

    return buildShiftOperationalSummary({
      shift,
      residents: residentSummaries,
      generatedAt: referenceTime,
    });
  }

  private async getActiveShiftIds() {
    const shifts = await this.prisma.shift.findMany({
      where: { status: 'ACTIVE' },
      select: { id: true },
    });
    return shifts.map((shift) => shift.id);
  }
}
