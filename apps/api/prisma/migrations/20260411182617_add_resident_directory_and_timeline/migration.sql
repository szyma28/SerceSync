-- CreateEnum
CREATE TYPE "ResidentTimelineEntryType" AS ENUM ('CARE_GIVEN', 'OBSERVATION', 'PERSONAL_CARE', 'NUTRITION_HYDRATION', 'MOBILITY_REPOSITIONING', 'MEDICATION_NOTE', 'ESCALATION');

-- AlterEnum
ALTER TYPE "AuditEventKind" ADD VALUE 'RESIDENT_TIMELINE_ENTRY_CREATED';

-- AlterTable
ALTER TABLE "shifts" ADD COLUMN     "floorNumber" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "unitLabel" TEXT NOT NULL DEFAULT 'Willow Floor';

-- AlterTable
ALTER TABLE "tasks" ADD COLUMN     "residentId" UUID;

-- CreateTable
CREATE TABLE "residents" (
    "id" UUID NOT NULL,
    "fullName" TEXT NOT NULL,
    "roomNumber" INTEGER NOT NULL,
    "roomLabel" TEXT NOT NULL,
    "floorNumber" INTEGER NOT NULL,
    "unitLabel" TEXT NOT NULL,
    "recognitionImageKey" TEXT NOT NULL,
    "careSummary" TEXT NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "residents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "resident_timeline_entries" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "type" "ResidentTimelineEntryType" NOT NULL,
    "title" TEXT NOT NULL,
    "details" TEXT NOT NULL,
    "createdById" UUID,
    "shiftId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "resident_timeline_entries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "residents_floorNumber_isActive_idx" ON "residents"("floorNumber", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "residents_floorNumber_roomNumber_key" ON "residents"("floorNumber", "roomNumber");

-- CreateIndex
CREATE INDEX "resident_timeline_entries_residentId_createdAt_idx" ON "resident_timeline_entries"("residentId", "createdAt");

-- CreateIndex
CREATE INDEX "resident_timeline_entries_createdById_idx" ON "resident_timeline_entries"("createdById");

-- CreateIndex
CREATE INDEX "resident_timeline_entries_shiftId_idx" ON "resident_timeline_entries"("shiftId");

-- CreateIndex
CREATE INDEX "tasks_residentId_idx" ON "tasks"("residentId");

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "resident_timeline_entries" ADD CONSTRAINT "resident_timeline_entries_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "resident_timeline_entries" ADD CONSTRAINT "resident_timeline_entries_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "resident_timeline_entries" ADD CONSTRAINT "resident_timeline_entries_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
