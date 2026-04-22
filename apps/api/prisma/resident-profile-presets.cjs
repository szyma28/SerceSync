const aboutMeStatements = [
  'Enjoys a calm start to the day, warm drinks, and a little friendly conversation before care begins. Familiar step-by-step prompts help build confidence during the morning routine.',
  'Appreciates clear communication and knowing what is happening next. Quiet reassurance and a steady pace help the shift feel settled and predictable.',
  'Responds well to unhurried mobility support and regular comfort checks. Keeping favourite items close by helps each room visit feel more familiar.',
  'Values privacy, dignity, and gentle prompting during personal care. A relaxed tone and a few extra moments to process requests make support smoother.',
  'Looks forward to mealtimes and responds best when food and drinks are introduced with encouragement rather than urgency. A cheerful check-in helps appetite.',
  'Prefers a consistent routine with medication, meals, and rest kept visible in the day. Short updates about timing help reduce uncertainty.',
  'Benefits from regular repositioning, comfort aids, and calm explanations before touch-based care. Small adjustments and skin checks are usually well tolerated.',
  'Settles best with warm conversation, familiar staff, and continuity from one round to the next. Brief mood notes are especially helpful for handovers.',
  'Enjoys a steady rhythm to the day with comfort needs noticed early. Little acts of reassurance often make routine care feel more collaborative.',
  'Likes friendly conversation, a tidy room, and simple choices offered one at a time. Gentle encouragement helps maintain independence where possible.',
  'Prefers hydration support to be offered little and often throughout the shift. A calm presence and a familiar routine usually keep the day on track.',
  'Responds well to observation rounds that feel conversational rather than clinical. A reassuring explanation before each check helps build trust.',
  'Appreciates support that balances mobility encouragement with plenty of time to rest between tasks. Consistent pacing prevents the day from feeling rushed.',
  'Values personal care that is respectful, predictable, and clearly introduced. Gentle prompts and patience help maintain confidence and comfort.',
  'Looks forward to meals and tends to do best when the dining environment stays calm and social. Encouragement works better than repeated pressure.',
  'Likes routines that stay visible and dependable from morning to evening. Familiar staff introductions and clear medication timing help the day feel settled.',
  'Benefits from comfort-led repositioning and regular skin-awareness checks. Support feels more effective when each step is explained in advance.',
  'Enjoys a warm, steady approach with extra attention to reassurance and continuity. Notes about mood and engagement are useful for the wider team.',
  'Prefers gentle reminders and support that keep independence in view. A calm tone, simple choices, and a little extra time often work best.',
  'Responds positively to relaxed conversation, familiar faces, and quiet reassurance during care. Routine check-ins help keep confidence steady through the shift.',
  'Enjoys peaceful mornings, a well-organised room, and time to settle before moving into care tasks. Hydration and comfort prompts are best offered softly.',
  'Appreciates clear explanations, regular observation, and a calm one-to-one style of support. Familiar routines reduce uncertainty and help build trust.',
  'Benefits from careful mobility support paired with reassurance and rest breaks. Encouragement is most effective when it feels collaborative rather than rushed.',
  'Values dignity, privacy, and predictable personal care routines. A warm introduction and step-by-step prompting help each interaction feel respectful.',
  'Looks forward to mealtimes and often responds best when food, drink, and company arrive together. Gentle encouragement helps maintain steady intake.',
  'Prefers a well-structured day with medication, rest, and reassurance communicated clearly. Keeping the plan visible helps reduce stress during busy periods.',
  'Responds well to comfort-focused support, repositioning, and practical check-ins that never feel hurried. Small updates make handovers more useful.',
  'Enjoys calm company, familiar conversation, and continuity from one visit to the next. Brief notes about mood, engagement, and comfort help the team align.',
  'Likes routine support that respects independence while keeping small comfort needs visible. A friendly check-in and clear next step help the day flow well.',
  'Prefers an unhurried environment with familiar voices and clear reassurance throughout care. Gentle pacing and consistent routines support comfort and trust.',
];

const residentProfilePresets = aboutMeStatements.map((aboutMe, index) => ({
  recognitionImageKey: `resident-${String(index + 1).padStart(2, '0')}`,
  aboutMe,
}));

module.exports = {
  residentProfilePresets,
};
