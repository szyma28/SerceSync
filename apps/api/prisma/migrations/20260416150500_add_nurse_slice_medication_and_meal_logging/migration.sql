-- CreateEnum
CREATE TYPE "TaskFocus" AS ENUM (
    'GENERAL',
    'HYDRATION',
    'OBSERVATION',
    'PERSONAL_CARE',
    'MOBILITY',
    'MEDICATION'
);

-- CreateEnum
CREATE TYPE "TaskClinicalPriority" AS ENUM (
    'ROUTINE',
    'PRIORITY',
    'TIME_CRITICAL'
);

-- CreateEnum
CREATE TYPE "MealType" AS ENUM (
    'BREAKFAST',
    'LUNCH',
    'DINNER',
    'SNACK'
);

-- CreateEnum
CREATE TYPE "MealIntakeAmount" AS ENUM (
    'NONE',
    'QUARTER',
    'HALF',
    'MOST',
    'ALL'
);

-- AlterTable
ALTER TABLE "tasks"
ADD COLUMN "focus" "TaskFocus" NOT NULL DEFAULT 'GENERAL',
ADD COLUMN "clinicalPriority" "TaskClinicalPriority" NOT NULL DEFAULT 'ROUTINE';

-- AlterTable
ALTER TABLE "resident_timeline_entries"
ADD COLUMN "mealType" "MealType",
ADD COLUMN "mealIntakeAmount" "MealIntakeAmount";
