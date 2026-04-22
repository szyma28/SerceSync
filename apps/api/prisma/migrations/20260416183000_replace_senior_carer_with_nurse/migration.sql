ALTER TYPE "RoleKey" RENAME VALUE 'SENIOR_CARER' TO 'NURSE';

UPDATE "roles"
SET "label" = 'Nurse'
WHERE "key" = 'NURSE';
