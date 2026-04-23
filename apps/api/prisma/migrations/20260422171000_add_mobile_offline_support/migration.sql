-- DropIndex
DROP INDEX "resident_timeline_entries_residentId_createdAt_idx";

-- AlterTable
ALTER TABLE "incidents"
ADD COLUMN "clientRequestId" TEXT;

-- AlterTable
ALTER TABLE "resident_timeline_entries"
ADD COLUMN "clientRequestId" TEXT,
ADD COLUMN "recordedAt" TIMESTAMP(3);

UPDATE "resident_timeline_entries"
SET "recordedAt" = "createdAt"
WHERE "recordedAt" IS NULL;

ALTER TABLE "resident_timeline_entries"
ALTER COLUMN "recordedAt" SET NOT NULL,
ALTER COLUMN "recordedAt" SET DEFAULT CURRENT_TIMESTAMP;

-- CreateTable
CREATE TABLE "mobile_refresh_sessions" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mobile_refresh_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "mobile_refresh_sessions_tokenHash_key" ON "mobile_refresh_sessions"("tokenHash");
CREATE INDEX "mobile_refresh_sessions_userId_expiresAt_idx" ON "mobile_refresh_sessions"("userId", "expiresAt");
CREATE INDEX "mobile_refresh_sessions_userId_revokedAt_idx" ON "mobile_refresh_sessions"("userId", "revokedAt");
CREATE UNIQUE INDEX "incidents_clientRequestId_key" ON "incidents"("clientRequestId");
CREATE UNIQUE INDEX "resident_timeline_entries_clientRequestId_key" ON "resident_timeline_entries"("clientRequestId");
CREATE INDEX "resident_timeline_entries_residentId_recordedAt_idx" ON "resident_timeline_entries"("residentId", "recordedAt");

-- AddForeignKey
ALTER TABLE "mobile_refresh_sessions"
ADD CONSTRAINT "mobile_refresh_sessions_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
