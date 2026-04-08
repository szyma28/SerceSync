-- CreateTable
CREATE TABLE "handover_acknowledgements" (
    "id" UUID NOT NULL,
    "handoverId" UUID NOT NULL,
    "acknowledgedById" UUID NOT NULL,
    "acknowledgedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "handover_acknowledgements_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "handover_acknowledgements_acknowledgedById_idx" ON "handover_acknowledgements"("acknowledgedById");

-- CreateIndex
CREATE UNIQUE INDEX "handover_acknowledgements_handoverId_acknowledgedById_key" ON "handover_acknowledgements"("handoverId", "acknowledgedById");

-- AddForeignKey
ALTER TABLE "handover_acknowledgements" ADD CONSTRAINT "handover_acknowledgements_handoverId_fkey" FOREIGN KEY ("handoverId") REFERENCES "handovers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "handover_acknowledgements" ADD CONSTRAINT "handover_acknowledgements_acknowledgedById_fkey" FOREIGN KEY ("acknowledgedById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
