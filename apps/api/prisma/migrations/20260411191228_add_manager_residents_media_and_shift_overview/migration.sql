-- AlterEnum
ALTER TYPE "AuditEventKind" ADD VALUE 'RESIDENT_TIMELINE_MEDIA_ATTACHED';

-- CreateTable
CREATE TABLE "resident_timeline_media" (
    "id" UUID NOT NULL,
    "entryId" UUID NOT NULL,
    "originalFileName" TEXT NOT NULL,
    "mediaType" TEXT NOT NULL,
    "byteSize" INTEGER NOT NULL,
    "storageKey" TEXT NOT NULL,
    "uploadedById" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "resident_timeline_media_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "resident_timeline_media_entryId_createdAt_idx" ON "resident_timeline_media"("entryId", "createdAt");

-- CreateIndex
CREATE INDEX "resident_timeline_media_uploadedById_idx" ON "resident_timeline_media"("uploadedById");

-- AddForeignKey
ALTER TABLE "resident_timeline_media" ADD CONSTRAINT "resident_timeline_media_entryId_fkey" FOREIGN KEY ("entryId") REFERENCES "resident_timeline_entries"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "resident_timeline_media" ADD CONSTRAINT "resident_timeline_media_uploadedById_fkey" FOREIGN KEY ("uploadedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
