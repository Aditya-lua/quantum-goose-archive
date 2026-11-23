// Storyboard: one entry per beat, in narration order.
// `line` = 1-based line in source-text/Barah_Bajkar_Satrah_Minute_Hindi.txt.
// `anchor` = exact manuscript words where the beat starts (omit = paragraph start).
// Beat start time comes from the alignment of that anchor; the beat ends where the
// next beat starts. This file is data only; components live in src/scenes/.
import type { Grade } from "../style/palette";

export type Transition = "cut" | "dissolve" | "fade";
export type Period = "present" | "flood-night" | "memory" | "hospital-memory" | "imagined" | "ending";

export type BeatDef = {
  id: string;
  seq: string;
  line: number;
  anchor?: string;
  location: string;
  period: Period;
  grade: Grade;
  chars: string[];
  action: string;
  framing: string;
  transition: Transition;
  props: string[];
  audio: string[];
};

const B = (
  id: string,
  line: number,
  anchor: string | undefined,
  location: string,
  period: Period,
  grade: Grade,
  chars: string[],
  action: string,
  framing: string,
  transition: Transition,
  props: string[] = [],
  audio: string[] = [],
): BeatDef => ({ id, seq: id.slice(0, 3), line, anchor, location, period, grade, chars, action, framing, transition, props, audio });

export const STORYBOARD: BeatDef[] = [
  // S00 — spoken title
  B("S00-01", 0, undefined, "house-front", "present", "present", [], "Title card in Devanagari over the house at night in rain, during the spoken title and the pause after it; the study window is the only warm light. (Manuscript lines 1 and 3 are not read in the recording.)", "Wide exterior, slow push to the lit window", "fade", ["title"], ["SFX: rain bed (fade in)"]),

  // S01 — the first truth (L1–11)
  B("S01-01", 5, undefined, "study", "present", "present", ["meeraAdult"], "Meera sits at her father's desk at night; her hand hovers above the recorder's Play key.", "Medium wide, slow push toward desk", "dissolve", ["recorder", "clock(stopped)", "lamp"], ["SFX: rain bed"]),
  B("S01-02", 5, "बटन दबाते ही", "study", "present", "present", ["meeraAdult"], "Finger presses Play; the reels begin to turn: the voice comes out.", "Insert: hand + recorder", "cut", ["recorder"], ["SFX: tape key click"]),
  B("S01-03", 5, "मीरा का हाथ वहीं ठहर गया।", "study", "present", "present", ["meeraAdult"], "Her hand freezes mid-air; rain on the window behind; she listens to his breathing.", "Medium close on Meera, window behind", "cut", ["recorder"], []),
  B("S01-04", 5, "धीमी और भारी", "study", "present", "present", [], "Wordless (line 7 is not read in the recording): the reels stop; the Play key pops up.", "Insert: reels", "cut", ["recorder"], ["SFX: tape stop click"]),
  B("S01-05", 13, undefined, "study", "present", "present", ["meeraAdult"], "The white slip with the cassette, in her father's hand: «पहले पूरी बात सुनना» (lines 9–11 are not read; shown as picture) — twenty-two years ago, too, he wanted to explain.", "Insert: note in her hand", "cut", ["cassette", "note"], []),

  // S02 — hospital memory (L13)
  B("S02-01", 13, "तब मीरा दस", "hospital", "hospital-memory", "hospital", ["meeraChild", "dineshYoung"], "Twenty-two years earlier: child Meera on a bench in the hospital verandah; covered shapes stay soft and distant.", "Wide corridor, static", "dissolve", ["bench"], []),
  B("S02-02", 13, "पिता ने उसका कंधा छुआ था।", "hospital", "hospital-memory", "hospital", ["meeraChild", "dineshYoung"], "Young Dinesh touches her shoulder; she jerks his hand away.", "Medium two-shot", "cut", [], []),
  B("S02-03", 13, "उसके बाद उस रात के बारे में", "study", "present", "present", ["meeraAdult"], "Back in the study: adult Meera's face in lamp light, the clock above.", "Close on Meera", "dissolve", ["clock(stopped)"], []),

  // S03 — her work, the sale, the cassette (L15–19)
  B("S03-01", 15, undefined, "delhi-studio", "present", "present", ["meeraAdult"], "Delhi: Meera in headphones cleaning an old song's waveform; her phone lights (home) and she silences it.", "Medium, screens glow", "cut", ["laptop", "headphones", "phone"], []),
  B("S03-02", 17, undefined, "study", "present", "present", ["meeraAdult"], "The emptied house: boxes; only the tape almirah left. She opens it and finds the cassette wrapped in a cotton handkerchief.", "Wide study, then insert hands", "cut", ["almirah", "boxes", "handkerchief", "cassette"], []),
  B("S03-03", 19, undefined, "study", "present", "present", ["meeraAdult"], "Playing again: the reels drag; she stops it.", "Insert recorder, then her hand", "cut", ["recorder"], ["SFX: tape key click"]),

  // S04 — the clock and the town's story (L21–25)
  B("S04-01", 21, undefined, "study", "present", "present", ["meeraAdult"], "The wall clock stopped at 12:17; Meera looks up at it (over-shoulder).", "OTS to clock, slow push", "cut", ["clock(stopped)"], []),
  B("S04-02", 23, undefined, "town", "flood-night", "flood", [], "Sahajanpur: the colour factory above the lower settlement; dye-coloured water enters the lanes.", "Extreme wide, slow pan", "dissolve", ["factory", "siren"], []),
  B("S04-03", 23, "नगर के सायरन की ज़िम्मेदारी", "town", "present", "present", [], "The siren on its pole; whispering neighbours; an inquiry file marked «लापरवाही».", "Inserts: siren, file", "cut", ["siren", "file"], []),
  B("S04-04", 25, undefined, "flood-lane", "flood-night", "flood", ["dineshYoung"], "Incomplete memory: a lone figure walks back through the rain toward the light. No faces.", "Wide, silhouette", "dissolve", [], []),

  // S05 — Kabir's shop (L27–43)
  B("S05-02", 29, undefined, "bazaar", "present", "present", ["meeraRain"], "Rainy bazaar; Meera in her raincoat, the cassette in her bag; Kabir's shop in the same place — phone covers behind the glass where radios once were. (Lines 27 and 31–41 are not read in the recording.)", "Wide tracking walk", "cut", ["shop front"], ["SFX: rain bed"]),
  B("S05-06", 43, undefined, "shop", "present", "present", ["kabir", "meeraAdult"], "Wordless establishing: inside, shutter half down, the cassette on the counter between them. Kabir says nothing; his eyes go to an old photo of his father with a radio. Meera realises what she has said.", "Close Kabir, insert photo, close Meera", "cut", ["photo"], []),

  // S06 — side A (L45–61)
  B("S06-01", 45, undefined, "shop", "present", "present", ["kabir", "meeraAdult"], "Kabir brings out a second deck; Meera connects her laptop; the waveform rises on screen.", "Inserts: cable, screen", "cut", ["deck", "laptop"], []),
  B("S06-02", 47, undefined, "shop", "present", "present", ["meeraAdult", "kabir"], "She listens in headphones as the full confession plays; at «मीरा» her eyes lift.", "Close Meera; insert playhead", "cut", ["headphones", "laptop"], []),
  B("S06-03", 51, undefined, "study", "imagined", "memoryWarm", ["dineshOld"], "As he speaks of the clock: his old hands set the hands back to 12:17 (as his words describe).", "Insert: clock and hands", "dissolve", ["clock(stopped)"], []),
  B("S06-04", 53, undefined, "shop", "present", "present", ["meeraAdult", "kabir"], "His cough covers the next words; a spike on the waveform.", "Insert waveform; close Meera", "dissolve", ["laptop"], []),
  B("S06-05", 55, undefined, "shop", "present", "present", ["meeraAdult"], "He speaks of the other side; she looks at the cassette; «मत जला देना» — her eyes close.", "Close Meera; insert cassette side B", "cut", ["cassette"], []),
  B("S06-06", 57, undefined, "shop", "present", "present", ["kabir", "meeraAdult"], "Silence on the tape, a chair scrape. Kabir: «दूसरी तरफ़ चलाएँ?» She nods.", "Two-shot", "cut", [], []),

  // S07 — side B: the warning (L63–89)
  B("S07-01", 63, undefined, "announcement-room", "flood-night", "flood", ["dineshYoung"], "Tape B: hiss, then the young voice. The announcement room on the flood night: young Dinesh at the microphone.", "Medium, rain at window", "dissolve", ["microphone", "siren switch"], []),
  B("S07-02", 67, undefined, "announcement-room", "flood-night", "flood", ["dineshYoung", "vikramNight"], "A faceless figure in the doorway orders the mic off; the young man protests about the water.", "Wide room; silhouette in door", "cut", [], []),
  B("S07-03", 69, undefined, "shop", "present", "present", ["meeraAdult"], "Present: Meera hears the flat, irritated second voice.", "Close Meera", "cut", ["headphones"], []),
  B("S07-04", 71, undefined, "announcement-room", "flood-night", "flood", ["dineshYoung", "vikramNight"], "«पानी बढ़ रहा है, साहब।» The figure: «...आपके सायरन से भगदड़ मच जाएगी।»", "Over-shoulder of the silhouette", "cut", [], []),
  B("S07-05", 75, undefined, "announcement-room", "flood-night", "flood", ["dineshYoung"], "Young Dinesh's own hand pulls the siren lever down; the red lamp dies.", "Insert: switch", "cut", ["siren switch"], ["SFX: switch click"]),
  B("S07-06", 77, undefined, "shop", "present", "present", ["meeraAdult"], "Rain swallows the words; Meera presses the headphones closer; a woman's voice rises behind.", "Close Meera, insert waveform", "cut", ["headphones"], []),
  B("S07-07", 79, undefined, "flood-gate", "flood-night", "flood", ["mother"], "Fragment: through the rain, a woman seen from behind calls toward the office.", "Wide, back view only", "cut", [], []),
  B("S07-08", 81, undefined, "shop", "present", "present", ["meeraAdult"], "Meera grips the table with both hands. «माँ।»", "Insert hands; close face", "cut", ["table"], []),
  B("S07-09", 85, undefined, "memory", "memory", "memoryWarm", ["mother"], "Soft fragments of her mother: bangles, a profile, breath — alive, hurried.", "Soft inserts", "dissolve", [], []),
  B("S07-10", 87, undefined, "shop", "present", "present", ["meeraAdult", "kabir"], "«बस करो» — Kabir stops the tape at once.", "Close Meera; insert stop key", "dissolve", ["deck"], ["SFX: stop key"]),

  // S08 — Anshu (L91–95)
  B("S08-01", 91, undefined, "shop", "present", "present", ["meeraAdult", "kabir"], "She sits a long time; the tea goes cold; a child rings a bicycle bell outside.", "Wide shop, glass front", "cut", ["tea glass"], []),
  B("S08-02", 91, "मीरा को अंशु का चेहरा याद आया,", "flood-lane", "flood-night", "flood", ["anshu", "meeraChild"], "Anshu's face; then the flood night: he holds her hand. «दीदी, तू हाथ तो नहीं छोड़ेगी?»", "Close Anshu; two-shot in rain", "dissolve", ["whistle"], []),
  B("S08-03", 95, undefined, "flood-lane", "flood-night", "flood", ["anshu", "meeraChild"], "The first push of water; she slips; small hands slide apart; her hand comes up empty.", "Inserts: hands in water", "cut", [], []),

  // S09 — the factory (L97–109)
  B("S09-01", 97, undefined, "factory", "present", "present", ["vikram(poster)"], "The closed factory; demolition notice; posters of Vikram Vashishth everywhere.", "Wide; push on poster", "dissolve", ["posters"], []),
  B("S09-02", 99, undefined, "factory", "present", "present", ["meeraAdult", "kabirStreet", "harish"], "Evening: the watchman stops them, then hears Dinesh's name and takes out his keys. «हरीश काका?»", "Wide gate; medium Harish", "cut", ["keys"], []),
  B("S09-03", 105, undefined, "announcement-room", "present", "present", ["meeraAdult"], "The mic room now: cut wires, a ring mark on the desk, the separate siren switch. She does not touch it.", "Wide room; insert hand hovering", "cut", ["siren switch"], []),
  B("S09-04", 107, undefined, "announcement-room", "memory", "memoryWarm", ["meeraChild", "dineshYoung"], "Memory: a child brings lunch to her father at this desk.", "Medium warm", "dissolve", ["tiffin"], []),
  B("S09-05", 109, undefined, "announcement-room", "present", "present", ["meeraAdult"], "Through the broken pane: the back verandah, then the school gate — only a few steps.", "POV through window; walk", "dissolve", [], []),

  // S10 — the gate (L111–133)
  B("S10-01", 111, undefined, "school-gate", "present", "present", ["meeraAdult", "harish", "kabirStreet"], "«स्कूल का फाटक कहाँ था?» Harish leads them behind.", "Wide walk", "cut", [], []),
  B("S10-02", 115, undefined, "school-gate", "present", "present", ["meeraAdult"], "The rusted gate, dirt road, two rooms and verandah. Memory as darkness, cries, something striking iron.", "Wide; flash inserts", "cut", ["gate", "chain"], []),
  B("S10-03", 117, undefined, "school-gate", "present", "present", ["meeraAdult", "harish", "kabirStreet"], "«फाटक बंद क्यों था?» Harish presses his lips; Kabir: tomorrow it will be torn down.", "Alternating", "cut", [], []),
  B("S10-04", 123, undefined, "school-gate", "present", "present", ["harish", "meeraAdult"], "Harish: the locked-gate order, the key in the office, trapped in the godown.", "Close Harish with keys", "cut", ["keys"], []),
  B("S10-05", 129, undefined, "school-gate", "present", "present", ["meeraAdult"], "She grips the bars: they reached the high ground and still could not get in.", "Close through bars", "cut", ["gate"], []),
  B("S10-06", 131, undefined, "school-gate", "present", "present", ["meeraAdult", "harish"], "«यह बात आपने किसी को बताई?» «नौकरी बचानी थी» ... the habit of silence.", "Close Harish", "cut", [], []),

  // S11 — the offer arrives (L135–141)
  B("S11-01", 135, undefined, "lane", "present", "day", ["meeraAdult", "kabirStreet"], "Walking back: a message from the old lawyer about Vikram's interest in the house. «शायद संयोग हो।» «शायद।»", "Walking two-shot; insert phone", "cut", ["phone"], []),

  // S12 — height mark and whistle (L143–145)
  B("S12-01", 143, undefined, "house-front", "present", "day", ["meeraAdult"], "She washes the verandah steps; mud runs off.", "Wide verandah", "cut", ["bucket", "cloth"], []),
  B("S12-02", 143, "पिता ने एक कोने में", "house-front", "present", "day", ["meeraAdult"], "The pencil height mark with «अंशु» in crooked letters; her cloth stops short of it.", "Insert pillar", "cut", ["height mark"], []),
  B("S12-03", 145, undefined, "house-front", "memory", "memoryWarm", ["meeraChild", "anshu"], "Warm afternoon: she teaches him to whistle; nothing, then a note; both laugh. The memory runs into water and stops.", "Medium two-shot, warm", "dissolve", ["whistle"], []),

  // S13 — restoration (L147–161)
  B("S13-01", 147, undefined, "study", "present", "present", ["meeraAdult", "kabir"], "Night at her father's desk: copies made, the original cassette set apart; Kabir in the outer room with wires.", "Wide study through door", "dissolve", ["laptop", "cassette"], []),
  B("S13-02", 149, undefined, "study", "present", "present", ["meeraAdult"], "Noise reduction: she lowers the rain but does not remove it; checks the original before each change.", "Insert screen; close Meera", "cut", ["laptop", "headphones"], []),
  B("S13-03", 151, undefined, "study", "present", "present", ["meeraAdult"], "Breath only; maybe a name. She loops it, then leaves the uncertain waveform untouched.", "Insert screen; hand withdraws", "cut", ["laptop"], []),
  B("S13-04", 153, undefined, "study", "present", "present", ["kabir", "meeraAdult"], "«कुछ समझ आया?» «नहीं।» ... «जो नहीं सुनाई देता, वह हम अपनी तरफ़ से नहीं भर सकते।»", "Kabir at door; close Meera", "cut", [], []),
  B("S13-05", 161, undefined, "study", "present", "present", ["meeraAdult"], "Two files saved side by side: the original and the reduced-noise copy.", "Insert screen", "cut", ["laptop"], []),

  // S14 — the rescue instruction (L163–179)
  B("S14-01", 163, undefined, "flood-gate", "flood-night", "flood", ["mother", "anshu"], "Her mother's sentence surfaces: «स्कूल वाला फाटक खोलो। बच्चे बाहर हैं।»", "Wide rain at the gate", "dissolve", [], []),
  B("S14-02", 167, undefined, "flood-gate", "flood-night", "flood", ["dineshYoung"], "Young Dinesh, panting: «मीरा कहाँ है?»", "Medium in rain", "cut", [], []),
  B("S14-03", 169, undefined, "flood-gate", "flood-night", "flood", ["mother", "anshu"], "Mother, holding Anshu, points back: «पीछे गिरी है। उसे उठाओ।»", "Medium", "cut", [], []),
  B("S14-04", 171, undefined, "announcement-room", "flood-night", "flood", [], "A crash, a cry, footsteps running from the microphone; the empty room.", "Static on mic", "cut", ["microphone"], []),
  B("S14-05", 173, undefined, "study", "present", "present", ["meeraAdult"], "Meera stops the recording.", "Insert key; close Meera", "cut", ["laptop"], []),
  B("S14-06", 175, undefined, "flood-lane", "memory", "flood", ["dineshYoung", "meeraChild"], "The memory completes: her father's fingers grip her shoulder; he carries her while she beats his back and reaches toward her mother.", "Medium in rain", "dissolve", [], []),
  B("S14-07", 177, undefined, "study", "present", "present", ["meeraAdult"], "But he switched off the siren. Both truths at once: she sits between lamp light and dark.", "Wide study, split light", "dissolve", ["siren switch (insert)"], []),

  // S15 — her guilt (L181–193)
  B("S15-01", 181, undefined, "study", "present", "present", ["meeraAdult"], "She takes her hand off the laptop; tools clink; «मैंने उसका हाथ छोड़ा था।»", "Close Meera", "cut", [], []),
  B("S15-02", 183, undefined, "study", "present", "present", ["kabir", "meeraAdult"], "Kabir at the door; their exchange.", "Two-shot through door", "cut", [], []),
  B("S15-03", 191, undefined, "study", "present", "present", ["kabir", "meeraAdult"], "«दस साल की बच्ची के हाथ में पूरे कारखाने की ज़िम्मेदारी नहीं थी।» She bows her head; he leaves.", "Close Kabir; close Meera", "cut", [], []),

  // S16 — diary and letter (L195–211)
  B("S16-01", 195, undefined, "study", "present", "present", ["meeraAdult"], "The drawer: the diary, her childhood school ID inside, a page written on.", "Insert drawer and diary", "cut", ["diary", "ID card"], []),
  B("S16-02", 197, undefined, "study", "present", "present", [], "Diary page in his hand: «आज फिर फ़ोन किया...»", "Insert page", "cut", ["diary"], []),
  B("S16-03", 199, undefined, "study", "present", "present", [], "Hospital expense accounts; then an unfinished letter.", "Insert pages", "cut", ["diary", "letter"], []),
  B("S16-04", 201, undefined, "study", "present", "present", [], "The letter, line by line, ending on the question he feared.", "Insert letter, slow tilt", "cut", ["letter"], []),
  B("S16-05", 203, undefined, "study", "present", "present", ["meeraAdult", "kabir"], "She lays the page down; Kabir enters; «वे डर गए थे।» «हाँ।» «इतने साल?»", "Medium two-shot", "cut", ["letter"], []),
  B("S16-06", 211, undefined, "study", "present", "present", ["kabir", "meeraAdult"], "Kabir pulls a chair close: his mother never threw away his Abba's watch.", "Medium two-shot", "cut", ["chair"], []),

  // S17 — Vikram's office (L213–245)
  B("S17-01", 213, undefined, "vikram-office", "present", "day", ["meeraAdult"], "Morning: Vikram's office.", "Wide establishing", "dissolve", [], []),
  B("S17-02", 215, undefined, "vikram-office", "present", "day", [], "The model of the new market: white cars, green trees, clean roads — a glass door where the gate stood.", "Insert model", "cut", ["market model"], []),
  B("S17-03", 217, undefined, "vikram-office", "present", "day", ["meeraAdult", "vikram"], "Without preamble she plays the order; Vikram's finger stops on the desk.", "Medium; insert finger", "cut", ["phone"], []),
  B("S17-04", 221, undefined, "vikram-office", "present", "day", ["vikram", "meeraAdult"], "«इतने पुराने टेप से क्या साबित होगा?» Her answer — a bluff about Harish; she feels her heartbeat in her throat.", "Singles", "cut", [], []),
  B("S17-05", 227, undefined, "vikram-office", "present", "day", ["vikram", "meeraAdult"], "He leans back: an honourable version of her father's name, the house taken care of.", "Medium Vikram", "cut", [], []),
  B("S17-06", 233, undefined, "vikram-office", "present", "day", ["meeraAdult"], "The purchase paper with an amount she has never seen at once: rent, debt, years.", "Insert paper; close Meera", "cut", ["purchase paper"], []),
  B("S17-07", 235, undefined, "vikram-office", "present", "day", ["meeraAdult", "vikram"], "«और सायरन?» «ग़लतफ़हमी थी।» «फाटक?» «तुम तब बच्ची थीं...»", "Fast singles", "cut", [], []),
  B("S17-08", 243, undefined, "vikram-office", "present", "day", ["meeraAdult", "vikram"], "She picks up her phone: «इसीलिए सुन रही हूँ।»", "Medium Meera rising", "cut", ["phone"], []),

  // S18 — roadside (L247–255)
  B("S18-01", 247, undefined, "roadside", "present", "day", ["meeraAdult"], "Outside, she calls Kabir: «हरीश काका से फिर बात करनी होगी।»", "Medium on the street", "cut", ["phone"], []),
  B("S18-02", 251, undefined, "roadside", "present", "day", ["meeraAdult"], "A father ties his daughter's shoelace while she tugs his shoulder; Meera takes out the letter.", "Wide; insert letter", "cut", ["letter"], []),
  B("S18-03", 253, undefined, "roadside", "present", "day", ["meeraAdult"], "In her mind: «आपको पहले बताना चाहिए था।» She folds the letter. The footsteps she remembered as running now come home.", "Close Meera; memory feet", "cut", ["letter"], []),

  // S19 — Harish at the gate (L257–265)
  B("S19-01", 257, undefined, "school-gate", "present", "day", ["harish"], "Before the gathering: Harish sits at the gate, chain undone.", "Wide gate", "dissolve", ["chain", "keys"], []),
  B("S19-02", 259, undefined, "school-gate", "present", "day", ["meeraAdult", "harish"], "«आज चाबी साथ लाए?» «उस रात के बाद से जेब में रहती है।»", "Close Harish; insert keys", "cut", ["keys"], []),
  B("S19-03", 263, undefined, "school-gate", "present", "day", ["meeraAdult", "harish"], "She sits beside him without consolation; «माइक पर बोल पाएँगे?» He looks at the empty verandah, nods.", "Two-shot", "cut", [], []),

  // S20 — the memorial (L267–307)
  B("S20-01", 267, undefined, "memorial", "present", "day", ["meeraMemorial"], "The courtyard fills; flowers; a stone with seventeen names, Anshu's last. Her hand closes on the whistle in her pocket.", "Wide; insert stone; insert whistle", "dissolve", ["memorial stone", "whistle"], []),
  B("S20-02", 269, undefined, "memorial", "present", "day", ["vikram"], "Vikram's speech: new beginnings, development, old wounds.", "Wide from the back of the crowd", "cut", ["microphone"], []),
  B("S20-03", 271, undefined, "memorial", "present", "day", ["kabirStreet", "meeraMemorial"], "Her name is called; Kabir connects the laptop to the microphone box.", "Insert cable", "cut", ["laptop", "mic box"], []),
  B("S20-04", 273, undefined, "memorial", "present", "day", ["meeraMemorial", "vikram"], "On stage she looks at Vikram until her hands stop shaking.", "Medium; insert hands", "cut", [], []),
  B("S20-05", 275, undefined, "memorial", "present", "day", ["meeraMemorial"], "«मैं दिनेश सक्सेना की बेटी हूँ...»", "Medium at mic", "cut", ["microphone"], []),
  B("S20-06", 277, undefined, "memorial", "present", "day", ["meeraMemorial"], "Her father's voice spreads over the courtyard; people shift.", "Wide crowd; speakers", "cut", ["speakers"], []),
  B("S20-07", 283, undefined, "memorial", "present", "day", ["meeraMemorial"], "She could have cut the first sentence — the edit she makes every day. Today she cut nothing.", "Insert timeline; close Meera", "cut", ["laptop"], []),
  B("S20-08", 287, undefined, "memorial", "present", "day", ["vikram", "meeraMemorial"], "Warning, order, click. Vikram stands: «इसे रोको...»", "Medium Vikram", "cut", [], []),
  B("S20-09", 291, undefined, "memorial", "present", "day", ["meeraMemorial", "kabirStreet"], "«असली कैसेट सुरक्षित है। जाँच होनी चाहिए...» Two men stop a man heading for the wires.", "Medium; wide", "cut", [], []),
  B("S20-10", 295, undefined, "memorial", "present", "day", ["harish"], "Mother's voice; the courtyard goes still; Harish rises with his keys and stops twice on the way.", "Wide; follow Harish", "cut", ["keys"], []),
  B("S20-11", 301, undefined, "memorial", "present", "day", ["harish"], "«मैं वहाँ चौकीदार था...»", "Medium Harish at mic", "cut", ["microphone"], []),
  B("S20-12", 303, undefined, "memorial", "present", "day", ["crowd"], "A woman stands: her sister was at that gate. A man asks why the inquiry didn't record it.", "Crowd singles", "cut", [], []),
  B("S20-13", 307, undefined, "memorial", "present", "day", ["meeraMemorial"], "Many voices; she does not stop the recording: running footsteps, the call, water, then a long silence.", "Wide, slow", "cut", [], []),

  // S21 — aftermath (L309–315)
  B("S21-01", 309, undefined, "aftermath", "present", "day", [], "No arrest; no courtroom. Newspapers ask questions; some call it fake; threats for Harish; Meera called again and again to give statements.", "Montage inserts", "dissolve", ["newspaper"], []),
  B("S21-02", 311, undefined, "school-gate", "present", "day", [], "But the gate was not torn down.", "Wide gate, idle machine", "cut", ["gate"], []),
  B("S21-03", 313, undefined, "aftermath", "present", "day", [], "Old inquiry and new statements; other families bring their papers to one table.", "Top-down table", "cut", ["files"], []),
  B("S21-04", 315, undefined, "house-front", "present", "day", ["meeraAdult"], "She stops the sale; leaves for Delhi; returns the next month — not to throw things away.", "Wide house, door", "cut", [], []),

  // S22 — the clock and the family tape (L317–333)
  B("S22-01", 317, undefined, "study", "ending", "ending", ["meeraAdult"], "She lifts the clock off the wall: dust; a small pencilled date by the battery.", "Medium; insert back", "dissolve", ["clock"], []),
  B("S22-02", 319, undefined, "study", "ending", "ending", ["meeraAdult"], "She hesitates with the clock in her lap; puts the battery in; the second hand shivers and moves on.", "Close hands; insert clock face", "cut", ["clock", "battery"], ["SFX: clock tick (from this moment)"]),
  B("S22-03", 321, undefined, "study", "ending", "ending", ["meeraAdult"], "Another cassette in the almirah, labelled in her mother's hand: «बच्चों की आवाज़ें». She plays it.", "Insert cassette; insert key", "cut", ["cassette", "recorder"], ["SFX: tape key click"]),
  B("S22-04", 325, undefined, "family-room", "memory", "memoryWarm", ["anshu", "meeraChild", "mother", "dineshYoung"], "The recording, remembered: Anshu's off-key whistle, little Meera's complaint, mother's laugh, father: «रहने दो। रिकॉर्ड होने दो।»", "Warm wide, then singles", "dissolve", ["whistle", "recorder"], []),
  B("S22-05", 331, undefined, "study", "ending", "ending", ["meeraAdult", "kabir"], "She laughs and cries; leaves the recorder running; Kabir stops at the door; she moves a chair for him.", "Medium; wide", "dissolve", ["recorder", "chair"], []),
  B("S22-06", 333, undefined, "study", "ending", "ending", ["meeraAdult", "kabir"], "Two people listening, four old voices, and the clock on the wall keeps going.", "Wide, slow pull out, fade", "cut", ["clock(running)", "recorder"], []),
];
