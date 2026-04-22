const { PrismaPg } = require('@prisma/adapter-pg');
const {
  PrismaClient,
  ResidentTimelineEntryType,
} = require('@prisma/client');
const { residentProfilePresets } = require('./resident-profile-presets.cjs');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    'DATABASE_URL must be defined before refreshing medication demo data.',
  );
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

const weekdayNames = [
  'SUNDAY',
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
];

const medicationAuditKinds = [
  'MEDICATION_CHART_CREATED',
  'MEDICATION_ORDER_CREATED',
  'MEDICATION_ORDER_UPDATED',
  'MEDICATION_ORDER_DEACTIVATED',
  'MEDICATION_SCHEDULE_CREATED',
  'MEDICATION_SCHEDULE_UPDATED',
  'MEDICATION_DOSE_INSTANCE_GENERATED',
  'MEDICATION_DOSE_ADMINISTERED',
  'MEDICATION_DOSE_REFUSED',
  'MEDICATION_DOSE_OMITTED',
  'MEDICATION_DOSE_DELAYED',
  'MEDICATION_DOSE_NOT_AVAILABLE',
  'MEDICATION_DOSE_HELD',
  'MEDICATION_PRN_EVENT_RECORDED',
  'MEDICATION_STOCK_TRANSACTION_RECORDED',
  'MEDICATION_ALLERGY_RECORDED',
  'MEDICATION_EXCEPTION_VIEWED',
  'MEDICATION_RECONCILIATION_STARTED',
  'MEDICATION_RECONCILIATION_COMPLETED',
  'MEDICATION_DOWNTIME_PACK_EXPORTED',
];

function addDays(date, days) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

function startOfDay(date) {
  const next = new Date(date);
  next.setHours(0, 0, 0, 0);
  return next;
}

function minutesAfter(date, minutes) {
  return new Date(date.getTime() + minutes * 60 * 1000);
}

function weekdayName(date) {
  return weekdayNames[date.getDay()];
}

function shiftDurationMinutes(shift) {
  return Math.max(
    60,
    Math.round((shift.endsAt.getTime() - shift.startsAt.getTime()) / 60000),
  );
}

function shiftProgressMinutes(shift, now) {
  return Math.max(
    0,
    Math.min(
      shiftDurationMinutes(shift) - 1,
      Math.round((now.getTime() - shift.startsAt.getTime()) / 60000),
    ),
  );
}

function clampWindowOffsets(start, end, shift) {
  const duration = shiftDurationMinutes(shift);
  const clampedStart = Math.max(0, Math.min(start, duration - 15));
  let clampedEnd = Math.max(clampedStart + 30, Math.min(end, duration));
  if (clampedEnd <= clampedStart) {
    clampedEnd = Math.min(duration, clampedStart + 60);
  }
  return {
    windowStartOffsetMinutes: clampedStart,
    windowEndOffsetMinutes: clampedEnd,
  };
}

function buildLiveWindow(shift, now, startDeltaMinutes, endDeltaMinutes) {
  const progress = shiftProgressMinutes(shift, now);
  return clampWindowOffsets(
    progress + startDeltaMinutes,
    progress + endDeltaMinutes,
    shift,
  );
}

function buildMorningWindow(shift) {
  return clampWindowOffsets(30, 90, shift);
}

function scheduledOrder(config) {
  return {
    sourceType: 'PHARMACY_SUPPLIED',
    route: 'oral',
    activeToday: false,
    schedules: [],
    ...config,
  };
}

function prnOrder(config) {
  return {
    sourceType: 'MANUAL_ENTRY',
    route: 'oral',
    isPRN: true,
    ...config,
  };
}

function buildMedicationProfiles(context) {
  const {
    todayWeekday,
    tomorrowWeekday,
    willowLiveWindow,
    willowLateLiveWindow,
    willowSoonWindow,
    willowMorningWindow,
  } = context;

  const tomorrowOnly = [tomorrowWeekday];
  const todayOnly = [todayWeekday];

  return [
    // Willow Floor
    {
      fullName: 'Margaret Evans',
      allergies: [
        {
          substance: 'Ibuprofen',
          reaction: 'Stomach irritation',
          severity: 'Mild',
        },
      ],
      orders: [
        scheduledOrder({
          medicationName: 'Paracetamol',
          formulation: 'tablet',
          strength: '500mg tablet',
          doseAmount: '2',
          doseUnit: 'tablet',
          instructions:
            'Give during the late-afternoon comfort round for chronic osteoarthritis pain, keeping movement and hydration support comfortable through the evening.',
          activeToday: true,
          schedules: [
            {
              roundLabel: 'EVENING',
              anchorType: 'SHIFT_START',
              daysOfWeek: todayOnly,
              ...willowLateLiveWindow,
            },
          ],
        }),
        prnOrder({
          medicationName: 'Paracetamol',
          formulation: 'oral suspension',
          strength: '250mg/5ml',
          doseAmount: '10',
          doseUnit: 'ml',
          instructions:
            'Offer when pain is reported or clearly observed, following the PRN protocol on the medication chart.',
          prnProtocol: {
            indication: 'Pain after movement or visible discomfort',
            whenToOffer:
              'Offer when the resident reports pain or shows clear discomfort after mobilising.',
            doseInstructions:
              'Give 10ml by mouth as required, using the prescribed PRN directions on the MAR.',
            minimumIntervalMinutes: 240,
            maxDosePer24Hours: 4,
            expectedEffect: 'Pain should ease within 30 to 45 minutes.',
            monitoringRequired:
              'Re-check comfort, mobility, and facial expression after 30 minutes.',
            whenToEscalate:
              'Escalate if pain continues, increases, or the resident becomes distressed.',
          },
          stock: {
            currentQuantity: '170',
            quantityUnit: 'ml',
            notes: 'Bottle opened this week and quantity re-checked after the last dose.',
            lastCheckedAtOffsetMinutes: -50,
            transaction: {
              transactionType: 'ADMINISTERED',
              quantity: '10',
              quantityUnit: 'ml',
              reason: 'PRN dose recorded during the active shift.',
            },
          },
          prnEvent: {
            eventType: 'PRN_ADMINISTERED',
            doseGiven: '10',
            doseUnit: 'ml',
            reason: 'Pain in the right hip after mobilising.',
            notes: 'Comfort improved after the dose and she settled in the lounge.',
            recordedAtOffsetMinutes: -40,
          },
        }),
      ],
      timelineEntries: [
        {
          title: 'PRN paracetamol administered',
          details:
            'PRN Paracetamol was recorded after discomfort during mobilisation. Comfort improved after review.',
          createdAtOffsetMinutes: -38,
        },
      ],
    },
    {
      fullName: 'Emma Parker',
      allergies: [
        {
          substance: 'Penicillin',
          reaction: 'Rash',
          severity: 'Moderate',
        },
      ],
      orders: [
        scheduledOrder({
          medicationName: 'Donepezil',
          formulation: 'tablet',
          strength: '5mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give during the cognitive support round and keep reassurance cues steady before and after administration.',
          activeToday: true,
          schedules: [
            {
              roundLabel: 'MIDDAY',
              anchorType: 'SHIFT_START',
              daysOfWeek: todayOnly,
              ...willowLiveWindow,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Elliot Turner',
      orders: [
        scheduledOrder({
          medicationName: 'Diclofenac',
          formulation: 'topical gel',
          strength: '1.16% gel',
          doseAmount: '4',
          doseUnit: 'g',
          route: 'topical',
          instructions:
            'Apply to both knees after the morning wash so transfers and mobility support remain more comfortable.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 45,
              windowEndOffsetMinutes: 120,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Thea Green',
      orders: [
        scheduledOrder({
          medicationName: 'Clotrimazole',
          formulation: 'cream',
          strength: '1% cream',
          doseAmount: '1',
          doseUnit: 'application',
          route: 'topical',
          instructions:
            'Apply after morning personal care to the affected skin fold area, using calm step-by-step prompting throughout the routine.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 60,
              windowEndOffsetMinutes: 135,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Amir Hussain',
      orders: [
        scheduledOrder({
          medicationName: 'Fortisip Compact Protein',
          formulation: 'oral nutritional supplement',
          strength: '125ml bottle',
          doseAmount: '1',
          doseUnit: 'bottle',
          instructions:
            'Offer with lunch and encourage slow sips so nutritional intake stays visible within the shift plan.',
          activeToday: true,
          schedules: [
            {
              roundLabel: 'MIDDAY',
              anchorType: 'SHIFT_START',
              daysOfWeek: todayOnly,
              ...willowLiveWindow,
            },
          ],
          doseInstance: {
            scheduleRoundLabel: 'MIDDAY',
            status: 'ADMINISTERED',
            dueWindow: willowLiveWindow,
            recordedAtOffsetMinutes: Math.min(
              willowLiveWindow.windowEndOffsetMinutes - 6,
              willowLiveWindow.windowStartOffsetMinutes + 24,
            ),
            reason: 'Administered with the supported meal.',
            notes:
              'Resident finished the supplement with lunch and remained settled afterwards.',
            eventType: 'ADMINISTERED',
            eventDoseGiven: '1',
            eventDoseUnit: 'bottle',
          },
        }),
      ],
      timelineEntries: [
        {
          title: 'Lunch supplement administered',
          details:
            'The midday Fortisip supplement was given with the supported meal and intake was recorded straight away.',
          createdAtOffsetMinutes: -18,
        },
      ],
    },
    {
      fullName: 'Sheila Morgan',
      orders: [
        scheduledOrder({
          medicationName: 'Amlodipine',
          formulation: 'tablet',
          strength: '5mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give in the morning with water and keep timing clear in the handover so the routine stays predictable.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 15,
              windowEndOffsetMinutes: 75,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Brian Foster',
      orders: [
        scheduledOrder({
          medicationName: 'Morphine Sulfate',
          formulation: 'oral solution',
          strength: '10mg/5ml',
          doseAmount: '2.5',
          doseUnit: 'ml',
          instructions:
            'Witnessed administration required. Use before the later comfort round so repositioning and pressure-area care remain tolerable.',
          isControlledDrug: true,
          requiresWitness: true,
          activeToday: true,
          schedules: [
            {
              roundLabel: 'EVENING',
              anchorType: 'SHIFT_START',
              daysOfWeek: todayOnly,
              ...willowSoonWindow,
            },
          ],
          stock: {
            currentQuantity: '45',
            quantityUnit: 'ml',
            notes: 'Controlled-drug balance checked with a second checker.',
            lastCheckedAtOffsetMinutes: -45,
            transaction: {
              transactionType: 'RECEIVED',
              quantity: '50',
              quantityUnit: 'ml',
              reason:
                'Controlled-drug balance confirmed during the opening stock check.',
              witnessRole: 'MANAGER',
            },
          },
        }),
      ],
    },
    {
      fullName: 'Joan Clarke',
      orders: [
        scheduledOrder({
          medicationName: 'Sertraline',
          formulation: 'tablet',
          strength: '50mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give with the morning round and keep reassurance steady so the routine feels familiar and unhurried.',
          activeToday: true,
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: todayOnly,
              ...willowMorningWindow,
            },
          ],
          doseInstance: {
            status: 'REFUSED',
            dueWindow: willowMorningWindow,
            recordedAtOffsetMinutes: 56,
            reason: 'Resident declined after explanation.',
            notes: 'Re-offer planned later if the resident agrees.',
            eventType: 'REFUSED',
            eventDoseUnit: 'tablet',
          },
        }),
      ],
      timelineEntries: [
        {
          title: 'Morning medication refused',
          details:
            'Morning Sertraline was declined after explanation and should be reviewed again later in the shift.',
          createdAtOffsetMinutes: -505,
        },
      ],
    },
    {
      fullName: 'Peter Wallace',
      orders: [
        scheduledOrder({
          medicationName: 'Aspirin',
          formulation: 'tablet',
          strength: '75mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give with the morning routine so small but important maintenance care stays visible and consistent.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 90,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Lily Bennett',
      orders: [
        scheduledOrder({
          medicationName: 'Melatonin',
          formulation: 'tablet',
          strength: '2mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Offer at bedtime when the room has settled so the evening routine stays calm and predictable.',
          schedules: [
            {
              roundLabel: 'BEDTIME',
              anchorType: 'FIXED_TIME',
              fixedTimeLocal: '20:00',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 60,
            },
          ],
        }),
      ],
    },
    // Maple Floor
    {
      fullName: 'Daniel Miller',
      orders: [
        scheduledOrder({
          medicationName: 'Lactulose',
          formulation: 'oral solution',
          strength: '3.1g/5ml',
          doseAmount: '15',
          doseUnit: 'ml',
          instructions:
            'Give in the morning and encourage fluids little and often so comfort remains the focus.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 30,
              windowEndOffsetMinutes: 90,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Alice Morton',
      orders: [
        scheduledOrder({
          medicationName: 'Citalopram',
          formulation: 'tablet',
          strength: '10mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give in the morning and continue calm observation and reassurance afterwards so the shift feels settled and predictable.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 30,
              windowEndOffsetMinutes: 90,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Isaac Collins',
      orders: [
        scheduledOrder({
          medicationName: 'Senna',
          formulation: 'tablet',
          strength: '7.5mg tablet',
          doseAmount: '2',
          doseUnit: 'tablet',
          instructions:
            'Give at bedtime if bowel care is still required so reduced mobility does not add discomfort overnight.',
          schedules: [
            {
              roundLabel: 'BEDTIME',
              anchorType: 'FIXED_TIME',
              fixedTimeLocal: '20:00',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 60,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Sophie Brooks',
      orders: [
        scheduledOrder({
          medicationName: 'Hypromellose',
          formulation: 'eye drops',
          strength: '0.3% eye drops',
          doseAmount: '1',
          doseUnit: 'drop',
          route: 'ophthalmic',
          instructions:
            'Instil one drop into each eye after the morning wash so personal care prompting stays gentle and comfortable.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 50,
              windowEndOffsetMinutes: 120,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Thomas Walker',
      orders: [
        scheduledOrder({
          medicationName: 'Metformin',
          formulation: 'tablet',
          strength: '500mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give with lunch and record how much was eaten so nutritional follow-up stays visible to the team.',
          schedules: [
            {
              roundLabel: 'MIDDAY',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 240,
              windowEndOffsetMinutes: 330,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Simone Price',
      orders: [
        scheduledOrder({
          medicationName: 'Levothyroxine',
          formulation: 'tablet',
          strength: '50mcg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give before breakfast with water so the medication timing remains clear and consistent for the morning team.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 45,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Chloe Hughes',
      orders: [
        scheduledOrder({
          medicationName: 'Paracetamol',
          formulation: 'tablet',
          strength: '500mg tablet',
          doseAmount: '2',
          doseUnit: 'tablet',
          instructions:
            'Give during the evening comfort round before repositioning for bed so soreness does not build through the night.',
          schedules: [
            {
              roundLabel: 'EVENING',
              anchorType: 'FIXED_TIME',
              fixedTimeLocal: '18:00',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 60,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'James Carter',
      orders: [
        scheduledOrder({
          medicationName: 'Mirtazapine',
          formulation: 'tablet',
          strength: '15mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give at bedtime so the evening routine stays reassuring and sleep settles more smoothly.',
          schedules: [
            {
              roundLabel: 'BEDTIME',
              anchorType: 'FIXED_TIME',
              fixedTimeLocal: '20:30',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 60,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Hannah Dixon',
      orders: [
        scheduledOrder({
          medicationName: 'Latanoprost',
          formulation: 'eye drops',
          strength: '50mcg/ml',
          doseAmount: '1',
          doseUnit: 'drop',
          route: 'ophthalmic',
          instructions:
            'Instil one drop into each eye at bedtime so routine eye care stays visible even on settled shifts.',
          schedules: [
            {
              roundLabel: 'BEDTIME',
              anchorType: 'FIXED_TIME',
              fixedTimeLocal: '20:00',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 45,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Mark Osei',
      allergies: [
        {
          substance: 'Codeine',
          reaction: 'Nausea',
          severity: 'Moderate',
        },
      ],
      orders: [
        scheduledOrder({
          medicationName: 'Apixaban',
          formulation: 'tablet',
          strength: '5mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give with the evening meal so regular maintenance care stays steady and continuity remains strong.',
          schedules: [
            {
              roundLabel: 'EVENING',
              anchorType: 'FIXED_TIME',
              fixedTimeLocal: '18:00',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 60,
            },
          ],
        }),
      ],
    },
    // Cedar Floor
    {
      fullName: 'Agnes Cook',
      orders: [
        scheduledOrder({
          medicationName: 'Furosemide',
          formulation: 'tablet',
          strength: '20mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give in the morning and keep drinks and fluid balance visible so comfort remains steady through the day.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 15,
              windowEndOffsetMinutes: 75,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Zara Khan',
      orders: [
        scheduledOrder({
          medicationName: 'Bisoprolol',
          formulation: 'tablet',
          strength: '2.5mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give in the morning with pulse observation and a calm explanation so the follow-up feels reassuring rather than rushed.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 30,
              windowEndOffsetMinutes: 90,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Mabel Reed',
      orders: [
        scheduledOrder({
          medicationName: 'Calcium with Vitamin D',
          formulation: 'tablet',
          strength: '1.5g/400 unit tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give with lunch as part of the mobility-support plan, keeping bone health and safe movement visible in daily care.',
          schedules: [
            {
              roundLabel: 'MIDDAY',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 240,
              windowEndOffsetMinutes: 330,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Amelia Lewis',
      orders: [
        scheduledOrder({
          medicationName: 'Hydrocortisone',
          formulation: 'cream',
          strength: '1% cream',
          doseAmount: '1',
          doseUnit: 'application',
          route: 'topical',
          instructions:
            'Apply to the affected hand patches after morning personal care, using clear and respectful prompting throughout.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 50,
              windowEndOffsetMinutes: 120,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Simon Fletcher',
      orders: [
        scheduledOrder({
          medicationName: 'Omeprazole',
          formulation: 'capsule',
          strength: '20mg capsule',
          doseAmount: '1',
          doseUnit: 'capsule',
          instructions:
            'Give before breakfast so eating feels more comfortable and nutritional encouragement is easier to maintain.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 45,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Jean Porter',
      orders: [
        scheduledOrder({
          medicationName: 'Pantoprazole',
          formulation: 'tablet',
          strength: '20mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give before breakfast so the timing remains clear and easy to follow for the morning team.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 45,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Frank Russell',
      orders: [
        scheduledOrder({
          medicationName: 'Gabapentin',
          formulation: 'capsule',
          strength: '100mg capsule',
          doseAmount: '1',
          doseUnit: 'capsule',
          instructions:
            'Give with the evening meal to ease discomfort before later positioning and settling for the night.',
          schedules: [
            {
              roundLabel: 'EVENING',
              anchorType: 'FIXED_TIME',
              fixedTimeLocal: '18:00',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 0,
              windowEndOffsetMinutes: 60,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Olive Chapman',
      orders: [
        scheduledOrder({
          medicationName: 'Citalopram',
          formulation: 'tablet',
          strength: '10mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give in the morning and keep continuity notes visible so reassurance stays consistent from one visit to the next.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 15,
              windowEndOffsetMinutes: 75,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Tara Banks',
      orders: [
        scheduledOrder({
          medicationName: 'Folic Acid',
          formulation: 'tablet',
          strength: '5mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          instructions:
            'Give in the morning so routine maintenance care stays visible without disrupting an otherwise settled day.',
          schedules: [
            {
              roundLabel: 'MORNING',
              anchorType: 'SHIFT_START',
              daysOfWeek: tomorrowOnly,
              windowStartOffsetMinutes: 45,
              windowEndOffsetMinutes: 105,
            },
          ],
        }),
      ],
    },
    {
      fullName: 'Ryan Coleman',
      orders: [
        prnOrder({
          medicationName: 'Salbutamol',
          formulation: 'inhaler',
          strength: '100mcg',
          doseAmount: '2',
          doseUnit: 'puff',
          route: 'inhaled',
          instructions:
            'Offer when shortness of breath is reported, following the PRN directions on the MAR and keeping reassurance steady during administration.',
          prnProtocol: {
            indication: 'Shortness of breath or wheeze',
            whenToOffer:
              'Offer when the resident reports breathlessness or audible wheeze.',
            doseInstructions:
              'Give two puffs via spacer as prescribed and record the response.',
            minimumIntervalMinutes: 240,
            maxDosePer24Hours: 4,
            expectedEffect: 'Breathing should ease within 10 minutes.',
            monitoringRequired:
              'Monitor respiratory comfort and escalate if symptoms continue.',
            whenToEscalate:
              'Escalate if symptoms persist, worsen, or the resident looks distressed.',
          },
          stock: {
            currentQuantity: '1',
            quantityUnit: 'inhaler',
            notes: 'Spare inhaler available in the treatment room.',
            lastCheckedAtOffsetMinutes: -30,
          },
        }),
      ],
    },
  ];
}

async function loadRequiredUsers() {
  const users = await prisma.user.findMany({
    where: {
      email: {
        in: [
          'manager@sercesync.local',
          'nurse@sercesync.local',
          'maple-nurse@sercesync.local',
          'cedar-nurse@sercesync.local',
        ],
      },
    },
    select: {
      id: true,
      email: true,
      displayName: true,
    },
  });

  const byEmail = new Map(users.map((entry) => [entry.email, entry]));
  const manager = byEmail.get('manager@sercesync.local');
  const willowNurse = byEmail.get('nurse@sercesync.local');
  const mapleNurse = byEmail.get('maple-nurse@sercesync.local');
  const cedarNurse = byEmail.get('cedar-nurse@sercesync.local');

  if (!manager || !willowNurse || !mapleNurse || !cedarNurse) {
    throw new Error(
      'Expected manager and floor nurse demo accounts were not all present.',
    );
  }

  return {
    manager,
    byFloor: new Map([
      [1, willowNurse],
      [2, mapleNurse],
      [3, cedarNurse],
    ]),
  };
}

async function loadActiveShifts(now) {
  const shifts = await prisma.shift.findMany({
    where: {
      status: 'ACTIVE',
      startsAt: { lte: now },
      endsAt: { gt: now },
    },
    orderBy: [{ floorNumber: 'asc' }, { startsAt: 'desc' }],
    select: {
      id: true,
      floorNumber: true,
      unitLabel: true,
      startsAt: true,
      endsAt: true,
    },
  });

  const byFloor = new Map();
  for (const shift of shifts) {
    if (!byFloor.has(shift.floorNumber)) {
      byFloor.set(shift.floorNumber, shift);
    }
  }

  for (const floorNumber of [1, 2, 3]) {
    if (!byFloor.has(floorNumber)) {
      throw new Error(`Expected an active shift for floor ${floorNumber}.`);
    }
  }

  return byFloor;
}

async function clearMedicationDomain() {
  await prisma.auditEvent.deleteMany({
    where: {
      kind: {
        in: medicationAuditKinds,
      },
    },
  });
  await prisma.residentTimelineEntry.deleteMany({
    where: {
      type: ResidentTimelineEntryType.MEDICATION_NOTE,
    },
  });
  await prisma.medicationReconciliation.deleteMany();
  await prisma.medicationStockTransaction.deleteMany();
  await prisma.medicationAdministrationEvent.deleteMany();
  await prisma.medicationDoseInstance.deleteMany();
  await prisma.medicationSchedule.deleteMany();
  await prisma.pRNProtocol.deleteMany();
  await prisma.medicationStockRecord.deleteMany();
  await prisma.medicationAllergyIntolerance.deleteMany();
  await prisma.medicationChangeLog.deleteMany();
  await prisma.medicationOrder.deleteMany();
  await prisma.residentMedicationChart.deleteMany();
}

async function refreshResidentProfiles(residents) {
  if (residents.length < residentProfilePresets.length) {
    throw new Error(
      `Expected at least ${residentProfilePresets.length} residents but found ${residents.length}.`,
    );
  }

  await prisma.$transaction(
    residentProfilePresets.map((preset, index) =>
      prisma.resident.update({
        where: {
          id: residents[index].id,
        },
        data: {
          recognitionImageKey: preset.recognitionImageKey,
          aboutMe: preset.aboutMe,
        },
      }),
    ),
  );
}

async function main() {
  const now = new Date();
  const today = startOfDay(now);
  const tomorrow = addDays(today, 1);
  const todayWeekday = weekdayName(now);
  const tomorrowWeekday = weekdayName(tomorrow);

  const [existingDemoTestOrders, users, shifts, residents] = await Promise.all([
    prisma.medicationOrder.count({
      where: {
        medicationName: {
          startsWith: 'Demo Test',
        },
      },
    }),
    loadRequiredUsers(),
    loadActiveShifts(now),
    prisma.resident.findMany({
      where: {
        isActive: true,
      },
      orderBy: [{ floorNumber: 'asc' }, { roomNumber: 'asc' }],
      select: {
        id: true,
        fullName: true,
        roomLabel: true,
        roomNumber: true,
        floorNumber: true,
        unitLabel: true,
      },
    }),
  ]);

  const residentsByName = new Map(
    residents.map((resident) => [resident.fullName, resident]),
  );

  await refreshResidentProfiles(residents);

  const willowShift = shifts.get(1);
  const medicationProfiles = buildMedicationProfiles({
    todayWeekday,
    tomorrowWeekday,
    willowLiveWindow: buildLiveWindow(willowShift, now, -50, 40),
    willowLateLiveWindow: buildLiveWindow(willowShift, now, -20, 70),
    willowSoonWindow: buildLiveWindow(willowShift, now, 5, 75),
    willowMorningWindow: buildMorningWindow(willowShift),
  });

  await clearMedicationDomain();

  let chartCount = 0;
  let orderCount = 0;
  let allergyCount = 0;
  let timelineCount = 0;

  for (const profile of medicationProfiles) {
    const resident = residentsByName.get(profile.fullName);
    if (!resident) {
      throw new Error(`Resident "${profile.fullName}" was not found.`);
    }

    const floorUser = users.byFloor.get(resident.floorNumber);
    const shift = shifts.get(resident.floorNumber);
    if (!floorUser || !shift) {
      throw new Error(
        `Missing active shift or assigned nurse for floor ${resident.floorNumber}.`,
      );
    }

    const chart = await prisma.residentMedicationChart.create({
      data: {
        residentId: resident.id,
        status: 'ACTIVE',
        createdByUserId: users.manager.id,
        reviewedByUserId: users.manager.id,
      },
    });
    chartCount += 1;

    await prisma.auditEvent.create({
      data: {
        kind: 'MEDICATION_CHART_CREATED',
        userId: users.manager.id,
        residentId: resident.id,
        details: {
          residentName: resident.fullName,
          source: 'refresh-medication-demo-data',
        },
      },
    });

    for (const allergy of profile.allergies ?? []) {
      await prisma.medicationAllergyIntolerance.create({
        data: {
          residentId: resident.id,
          substance: allergy.substance,
          reaction: allergy.reaction ?? null,
          severity: allergy.severity ?? null,
          recordedByUserId: users.manager.id,
        },
      });
      allergyCount += 1;

      await prisma.auditEvent.create({
        data: {
          kind: 'MEDICATION_ALLERGY_RECORDED',
          userId: users.manager.id,
          residentId: resident.id,
          details: {
            substance: allergy.substance,
            reaction: allergy.reaction ?? null,
            severity: allergy.severity ?? null,
            source: 'refresh-medication-demo-data',
          },
        },
      });
    }

    for (const orderPreset of profile.orders) {
      const order = await prisma.medicationOrder.create({
        data: {
          residentId: resident.id,
          chartId: chart.id,
          medicationName: orderPreset.medicationName,
          formulation: orderPreset.formulation ?? null,
          strength: orderPreset.strength ?? null,
          doseAmount: orderPreset.doseAmount,
          doseUnit: orderPreset.doseUnit,
          route: orderPreset.route,
          instructions: orderPreset.instructions,
          startDate: today,
          isActive: true,
          isControlledDrug: orderPreset.isControlledDrug ?? false,
          requiresWitness: orderPreset.requiresWitness ?? false,
          isPRN: orderPreset.isPRN ?? false,
          sourceType: orderPreset.sourceType,
          createdByUserId: users.manager.id,
          updatedByUserId: users.manager.id,
        },
      });
      orderCount += 1;

      await prisma.medicationChangeLog.create({
        data: {
          medicationOrderId: order.id,
          residentId: resident.id,
          changedByUserId: users.manager.id,
          changeType: 'CREATED',
          previousValueJson: null,
          newValueJson: {
            medicationName: order.medicationName,
            formulation: order.formulation,
            strength: order.strength,
            doseAmount: order.doseAmount,
            doseUnit: order.doseUnit,
            route: order.route,
            instructions: order.instructions,
            isPRN: order.isPRN,
            sourceType: order.sourceType,
          },
          reason:
            'Curated demo medication order recorded for the local eMAR walkthrough.',
        },
      });

      await prisma.auditEvent.create({
        data: {
          kind: 'MEDICATION_ORDER_CREATED',
          userId: users.manager.id,
          residentId: resident.id,
          medicationOrderId: order.id,
          details: {
            medicationName: order.medicationName,
            source: 'refresh-medication-demo-data',
          },
        },
      });

      const schedulesByRoundLabel = new Map();
      for (const schedulePreset of orderPreset.schedules ?? []) {
        const schedule = await prisma.medicationSchedule.create({
          data: {
            medicationOrderId: order.id,
            roundLabel: schedulePreset.roundLabel,
            anchorType: schedulePreset.anchorType,
            windowStartOffsetMinutes:
              schedulePreset.windowStartOffsetMinutes ?? null,
            windowEndOffsetMinutes:
              schedulePreset.windowEndOffsetMinutes ?? null,
            fixedTimeLocal: schedulePreset.fixedTimeLocal ?? null,
            daysOfWeek:
              schedulePreset.daysOfWeek ??
              (orderPreset.activeToday ? [todayWeekday] : [tomorrowWeekday]),
            active: true,
          },
        });
        schedulesByRoundLabel.set(schedule.roundLabel, schedule);

        await prisma.auditEvent.create({
          data: {
            kind: 'MEDICATION_SCHEDULE_CREATED',
            userId: users.manager.id,
            residentId: resident.id,
            medicationOrderId: order.id,
            details: {
              medicationName: order.medicationName,
              roundLabel: schedule.roundLabel,
              anchorType: schedule.anchorType,
              source: 'refresh-medication-demo-data',
            },
          },
        });
      }

      if (orderPreset.prnProtocol) {
        await prisma.pRNProtocol.create({
          data: {
            residentId: resident.id,
            medicationOrderId: order.id,
            indication: orderPreset.prnProtocol.indication,
            whenToOffer: orderPreset.prnProtocol.whenToOffer,
            doseInstructions: orderPreset.prnProtocol.doseInstructions,
            minimumIntervalMinutes:
              orderPreset.prnProtocol.minimumIntervalMinutes ?? null,
            maxDosePer24Hours:
              orderPreset.prnProtocol.maxDosePer24Hours ?? null,
            expectedEffect: orderPreset.prnProtocol.expectedEffect ?? null,
            monitoringRequired:
              orderPreset.prnProtocol.monitoringRequired ?? null,
            whenToEscalate: orderPreset.prnProtocol.whenToEscalate ?? null,
            active: true,
            createdByUserId: users.manager.id,
          },
        });
      }

      let stockRecord = null;
      if (orderPreset.stock) {
        stockRecord = await prisma.medicationStockRecord.create({
          data: {
            residentId: resident.id,
            medicationOrderId: order.id,
            currentQuantity: orderPreset.stock.currentQuantity,
            quantityUnit: orderPreset.stock.quantityUnit,
            lastCheckedByUserId: floorUser.id,
            lastCheckedAt:
              orderPreset.stock.lastCheckedAtOffsetMinutes !== undefined
                ? minutesAfter(now, orderPreset.stock.lastCheckedAtOffsetMinutes)
                : null,
            notes: orderPreset.stock.notes ?? null,
          },
        });

        if (orderPreset.stock.transaction) {
          await prisma.medicationStockTransaction.create({
            data: {
              stockRecordId: stockRecord.id,
              residentId: resident.id,
              medicationOrderId: order.id,
              transactionType: orderPreset.stock.transaction.transactionType,
              quantity: orderPreset.stock.transaction.quantity,
              quantityUnit: orderPreset.stock.transaction.quantityUnit,
              recordedByUserId: floorUser.id,
              witnessUserId:
                orderPreset.stock.transaction.witnessRole === 'MANAGER'
                  ? users.manager.id
                  : null,
              reason: orderPreset.stock.transaction.reason ?? null,
              createdAt: now,
            },
          });

          await prisma.auditEvent.create({
            data: {
              kind: 'MEDICATION_STOCK_TRANSACTION_RECORDED',
              userId: floorUser.id,
              residentId: resident.id,
              medicationOrderId: order.id,
              details: {
                medicationName: order.medicationName,
                transactionType:
                  orderPreset.stock.transaction.transactionType,
                source: 'refresh-medication-demo-data',
              },
            },
          });
        }
      }

      if (orderPreset.doseInstance) {
        const schedule = schedulesByRoundLabel.get(
          orderPreset.doseInstance.scheduleRoundLabel ?? 'MORNING',
        );
        if (!schedule) {
          throw new Error(
            `Schedule "${orderPreset.doseInstance.scheduleRoundLabel}" was not created for ${resident.fullName}.`,
          );
        }

        const dueWindow =
          orderPreset.doseInstance.dueWindow ?? buildMorningWindow(shift);
        const dueWindowStart = minutesAfter(
          shift.startsAt,
          dueWindow.windowStartOffsetMinutes,
        );
        const dueWindowEnd = minutesAfter(
          shift.startsAt,
          dueWindow.windowEndOffsetMinutes,
        );
        const recordedAt =
          orderPreset.doseInstance.recordedAtOffsetMinutes !== undefined
            ? minutesAfter(
                shift.startsAt,
                orderPreset.doseInstance.recordedAtOffsetMinutes,
              )
            : null;

        const doseInstance = await prisma.medicationDoseInstance.create({
          data: {
            residentId: resident.id,
            medicationOrderId: order.id,
            scheduleId: schedule.id,
            shiftId: shift.id,
            dueWindowStart,
            dueWindowEnd,
            status: orderPreset.doseInstance.status,
            generatedAt: recordedAt ?? dueWindowStart,
            recordedByUserId: recordedAt ? floorUser.id : null,
            recordedAt,
            reason: orderPreset.doseInstance.reason ?? null,
            notes: orderPreset.doseInstance.notes ?? null,
            requiresWitness: order.requiresWitness,
            witnessUserId: order.requiresWitness ? users.manager.id : null,
          },
        });

        if (orderPreset.doseInstance.eventType) {
          await prisma.medicationAdministrationEvent.create({
            data: {
              doseInstanceId: doseInstance.id,
              residentId: resident.id,
              medicationOrderId: order.id,
              shiftId: shift.id,
              eventType: orderPreset.doseInstance.eventType,
              doseGiven: orderPreset.doseInstance.eventDoseGiven ?? null,
              doseUnit:
                orderPreset.doseInstance.eventDoseUnit ?? order.doseUnit,
              reason: orderPreset.doseInstance.reason ?? null,
              notes: orderPreset.doseInstance.notes ?? null,
              recordedByUserId: floorUser.id,
              recordedAt: recordedAt ?? dueWindowEnd,
              witnessUserId: order.requiresWitness ? users.manager.id : null,
            },
          });
        }

        await prisma.auditEvent.create({
          data: {
            kind:
              orderPreset.doseInstance.status === 'REFUSED'
                ? 'MEDICATION_DOSE_REFUSED'
                : orderPreset.doseInstance.status === 'ADMINISTERED'
                  ? 'MEDICATION_DOSE_ADMINISTERED'
                  : 'MEDICATION_DOSE_INSTANCE_GENERATED',
            userId: floorUser.id,
            shiftId: shift.id,
            residentId: resident.id,
            medicationOrderId: order.id,
            medicationDoseInstanceId: doseInstance.id,
            details: {
              medicationName: order.medicationName,
              roundLabel: schedule.roundLabel,
              source: 'refresh-medication-demo-data',
            },
          },
        });
      }

      if (orderPreset.prnEvent) {
        await prisma.medicationAdministrationEvent.create({
          data: {
            residentId: resident.id,
            medicationOrderId: order.id,
            shiftId: shift.id,
            eventType: orderPreset.prnEvent.eventType,
            doseGiven: orderPreset.prnEvent.doseGiven ?? null,
            doseUnit: orderPreset.prnEvent.doseUnit ?? null,
            reason: orderPreset.prnEvent.reason ?? null,
            notes: orderPreset.prnEvent.notes ?? null,
            recordedByUserId: floorUser.id,
            recordedAt: minutesAfter(
              now,
              orderPreset.prnEvent.recordedAtOffsetMinutes,
            ),
          },
        });

        await prisma.auditEvent.create({
          data: {
            kind: 'MEDICATION_PRN_EVENT_RECORDED',
            userId: floorUser.id,
            shiftId: shift.id,
            residentId: resident.id,
            medicationOrderId: order.id,
            details: {
              medicationName: order.medicationName,
              eventType: orderPreset.prnEvent.eventType,
              source: 'refresh-medication-demo-data',
            },
          },
        });
      }
    }

    for (const timelinePreset of profile.timelineEntries ?? []) {
      await prisma.residentTimelineEntry.create({
        data: {
          residentId: resident.id,
          shiftId: shift.id,
          createdById: floorUser.id,
          type: ResidentTimelineEntryType.MEDICATION_NOTE,
          title: timelinePreset.title,
          details: timelinePreset.details,
          createdAt: minutesAfter(now, timelinePreset.createdAtOffsetMinutes),
        },
      });
      timelineCount += 1;
    }
  }

  const [remainingDemoTestOrders, margaretResident, totalCharts, totalOrders] =
    await Promise.all([
      prisma.medicationOrder.count({
        where: {
          medicationName: {
            startsWith: 'Demo Test',
          },
        },
      }),
      prisma.resident.findFirst({
        where: {
          fullName: 'Margaret Evans',
        },
        select: {
          id: true,
        },
      }),
      prisma.residentMedicationChart.count(),
      prisma.medicationOrder.count(),
    ]);

  const margaretOrders = margaretResident
    ? await prisma.medicationOrder.findMany({
        where: {
          residentId: margaretResident.id,
          isActive: true,
        },
        orderBy: [{ isPRN: 'asc' }, { medicationName: 'asc' }],
        select: {
          medicationName: true,
          strength: true,
          isPRN: true,
        },
      })
    : [];

  console.log(
    `Removed ${existingDemoTestOrders} demo test orders and rebuilt medication data.`,
  );
  console.log(
    `Medication charts: ${totalCharts}, medication orders: ${totalOrders}, allergies: ${allergyCount}, medication timeline entries: ${timelineCount}.`,
  );
  console.log(`Remaining demo test orders: ${remainingDemoTestOrders}.`);
  console.log(
    `Margaret Evans active orders: ${margaretOrders
      .map((entry) =>
        `${entry.medicationName}${entry.strength ? ` ${entry.strength}` : ''}${entry.isPRN ? ' (PRN)' : ''}`,
      )
      .join('; ')}`,
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
