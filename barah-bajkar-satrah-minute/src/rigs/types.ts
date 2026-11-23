export type HairStyle =
  | "meeraAdult"
  | "meeraChild"
  | "dineshOld"
  | "dineshYoung"
  | "mother"
  | "anshu"
  | "kabir"
  | "vikram"
  | "harish"
  | "shortMale"
  | "bunFemale"
  | "plaitFemale";

export type TopKind = "kurta" | "shirt" | "frock" | "sari" | "coat" | "jacket" | "cardigan";
export type BottomKind = "trousers" | "salwar" | "sari" | "shorts" | "legs";

export type CharSpec = {
  id: string;
  name: string;
  H: number; // standing height in world units
  headFrac: number; // head height / H
  shoulder: number; // shoulder half-width / H
  hip: number; // hip half-width / H
  skin: string;
  skinShade: string;
  lip: string;
  hair: HairStyle;
  hairColor: string;
  hairShade: string;
  faceW: number; // horizontal face scale
  jaw: number; // 0 soft .. 1 square
  top: { kind: TopKind; color: string; shade: string; trim?: string; length: number };
  bottom: { kind: BottomKind; color: string; shade: string };
  sleeve: "long" | "half" | "three-quarter";
  shoe: string;
  acc: {
    glasses?: boolean;
    bindi?: boolean;
    moustache?: string;
    beard?: string;
    stubble?: string;
    earrings?: string;
    bangles?: string;
    watch?: boolean;
    cap?: string;
    dupatta?: { color: string; shade: string };
    pallu?: { color: string; shade: string; border: string };
    apron?: { color: string; shade: string };
    jacket?: { color: string; shade: string };
    whistle?: boolean;
    ribbons?: string;
    pencil?: boolean;
    wrinkles?: number; // 0..1
    underEye?: number; // 0..1 tiredness shading
  };
};

export type HandShape = "relaxed" | "fist" | "open" | "point" | "grip" | "hold" | "pinch";

export type ArmPose = {
  sh: number; // shoulder angle, degrees from hanging down, + forward (facing direction)
  el: number; // elbow bend, degrees, + bends forward/up
  wr?: number; // wrist bend
  hand?: HandShape;
};

export type Expr = {
  browInner: number; // -1 frown .. +1 raised inner (grief/worry)
  browY: number; // -1 lowered .. +1 raised
  lid: number; // 0 open .. 1 closed (upper lid droop)
  lower: number; // 0..1 lower lid raise (squint / smile)
  mouth: number; // -1 frown .. +1 smile
  open: number; // 0..1 mouth open (non-speech: gasp, laugh)
  press?: number; // 0..1 lips pressed (भींचना)
  tears?: number; // 0..1 wet eyes highlight
};

export type Stance = "stand" | "sit" | "crouch" | "walk";

export type Pose = {
  stance: Stance;
  walk?: number; // walk phase in cycles
  lean?: number; // torso lean deg (+ toward facing)
  headTilt?: number; // deg (+ nod down/forward)
  headTurn?: number; // -1 frontal .. +1 profile (feature shift)
  gazeX?: number; // -1..1
  gazeY?: number; // -1..1 (+ down)
  near?: ArmPose;
  far?: ArmPose;
  expr?: Partial<Expr> | ExprName;
  talk?: number; // 0..1 speech mouth opening (only for aligned direct speech)
  blink?: number; // 0..1 eyelid closure from blink()
  breath?: number; // -1..1
  view?: "front" | "back";
  shoulderUp?: number; // shrug/tension 0..1
};

export type ExprName =
  | "neutral"
  | "listen"
  | "tense"
  | "grief"
  | "shock"
  | "anger"
  | "soft"
  | "sad"
  | "crying"
  | "laugh"
  | "tired"
  | "stern"
  | "smug"
  | "fear"
  | "resolve"
  | "pressed";
