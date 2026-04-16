-- CreateEnum
CREATE TYPE "ResidentPriorityLevel" AS ENUM ('GREEN', 'AMBER', 'RED');

-- CreateEnum
CREATE TYPE "IncidentSeverity" AS ENUM ('AMBER', 'RED');

-- CreateEnum
CREATE TYPE "IncidentStatus" AS ENUM ('OPEN', 'ACKNOWLEDGED', 'RESOLVED');

-- CreateEnum
CREATE TYPE "IncidentCategory" AS ENUM ('FALL', 'MEDICATION', 'BEHAVIOUR', 'INJURY', 'OTHER');

-- CreateEnum
CREATE TYPE "PersonalCareSubtype" AS ENUM ('SHOWER', 'CONTINENCE', 'FOOT_CARE', 'SKIN_CARE');

-- AlterEnum
ALTER TYPE "AuditEventKind" ADD VALUE 'INCIDENT_CREATED';

-- AlterEnum
ALTER TYPE "AuditEventKind" ADD VALUE 'INCIDENT_MEDIA_ATTACHED';

-- AlterEnum
ALTER TYPE "AuditEventKind" ADD VALUE 'INCIDENT_ACKNOWLEDGED';

-- AlterEnum
ALTER TYPE "AuditEventKind" ADD VALUE 'INCIDENT_RESOLVED';

-- AlterTable
ALTER TABLE "residents"
ADD COLUMN "baselinePriority" "ResidentPriorityLevel" NOT NULL DEFAULT 'GREEN';

-- AlterTable
ALTER TABLE "resident_timeline_entries"
ADD COLUMN "personalCareSubtype" "PersonalCareSubtype";

-- CreateTable
CREATE TABLE "incidents" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "shiftId" UUID NOT NULL,
    "createdById" UUID,
    "severity" "IncidentSeverity" NOT NULL,
    "status" "IncidentStatus" NOT NULL DEFAULT 'OPEN',
    "category" "IncidentCategory" NOT NULL,
    "title" TEXT NOT NULL,
    "details" TEXT NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acknowledgedAt" TIMESTAMP(3),
    "acknowledgedById" UUID,
    "resolvedAt" TIMESTAMP(3),
    "resolvedById" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "incidents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "incident_media" (
    "id" UUID NOT NULL,
    "incidentId" UUID NOT NULL,
    "originalFileName" TEXT NOT NULL,
    "mediaType" TEXT NOT NULL,
    "byteSize" INTEGER NOT NULL,
    "storageKey" TEXT NOT NULL,
    "uploadedById" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "incident_media_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "incidents_residentId_status_idx" ON "incidents"("residentId", "status");

-- CreateIndex
CREATE INDEX "incidents_shiftId_status_idx" ON "incidents"("shiftId", "status");

-- CreateIndex
CREATE INDEX "incidents_severity_status_createdAt_idx" ON "incidents"("severity", "status", "createdAt");

-- CreateIndex
CREATE INDEX "incidents_createdById_idx" ON "incidents"("createdById");

-- CreateIndex
CREATE INDEX "incidents_acknowledgedById_idx" ON "incidents"("acknowledgedById");

-- CreateIndex
CREATE INDEX "incidents_resolvedById_idx" ON "incidents"("resolvedById");

-- CreateIndex
CREATE INDEX "incident_media_incidentId_createdAt_idx" ON "incident_media"("incidentId", "createdAt");

-- CreateIndex
CREATE INDEX "incident_media_uploadedById_idx" ON "incident_media"("uploadedById");

-- AddForeignKey
ALTER TABLE "incidents" ADD CONSTRAINT "incidents_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidents" ADD CONSTRAINT "incidents_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "shifts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidents" ADD CONSTRAINT "incidents_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidents" ADD CONSTRAINT "incidents_acknowledgedById_fkey" FOREIGN KEY ("acknowledgedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incidents" ADD CONSTRAINT "incidents_resolvedById_fkey" FOREIGN KEY ("resolvedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incident_media" ADD CONSTRAINT "incident_media_incidentId_fkey" FOREIGN KEY ("incidentId") REFERENCES "incidents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "incident_media" ADD CONSTRAINT "incident_media_uploadedById_fkey" FOREIGN KEY ("uploadedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
