type Vector2 = [x: number, y: number];
type Vector4 = [r: number, g: number, b: number, a: number];
type Sides = [left: number, right: number, top: number, bottom: number];
type Sizing = [kind: "fit"] | [kind: "fixed" | "ratio" | "grow", value: number];
type Placement = [kind: "flow"] | [kind: "fixed" | "relative", x: number, y: number];
type GradientStop = [r: number, g: number, b: number, a: number, position: number];
type Background =
    | [kind: "color", r: number, g: number, b: number, a: number]
    | [kind: "gradient", x: number, y: number, ...stops: number[]];
type Shadow = [
    left: number, right: number, top: number, bottom: number,
    blurRadius: number, spread: number,
    r: number, g: number, b: number, a: number,
];

type Alignment = "start" | "center" | "end";
type BorderStyle = "solid" | "dashed";
type Cursor = "default" | "text" | "pointer";
type Direction = "horizontal" | "vertical";
type Overflow = "visible" | "wrap";
type TextWrapping = "word" | "character" | "none";

interface Font {
    readonly __forbearFont: unique symbol;
}

interface Style {
    background?: Background;
    color?: Vector4;
    borderRadius?: number;
    borderColor?: Vector4;
    borderWidth?: Sides;
    borderStyle?: BorderStyle;
    shadow?: Shadow;
    font?: Font;
    fontWeight?: number;
    fontSize?: number;
    lineHeight?: number;
    textWrapping?: TextWrapping;
    cursor?: Cursor;
    overflow?: Overflow;
    placement?: Placement;
    zIndex?: number;
    minWidth?: number;
    maxWidth?: number;
    width?: Sizing;
    minHeight?: number;
    maxHeight?: number;
    height?: Sizing;
    translate?: Vector2;
    padding?: Sides;
    margin?: Sides;
    xJustification?: Alignment;
    yJustification?: Alignment;
    direction?: Direction;
}

declare function element(style: Style, children: () => void): void;
declare function text(style: Style, content: string): void;

declare function rgb(r: number, g: number, b: number): Vector4;
declare function rgba(r: number, g: number, b: number, a: number): Vector4;
declare function color(value: Vector4): Background;
declare function gradient(direction: Vector2, stops: GradientStop[]): Background;

declare function fit(): Sizing;
declare function fixed(value: number): Sizing;
declare function fixed(value: Vector2): Placement;
declare function ratio(value: number): Sizing;
declare function grow(value: number): Sizing;
declare function flow(): Placement;
declare function relative(value: Vector2): Placement;

declare function all(value: number): Sides;
declare function inLine(value: number): Sides;
declare function inLine(sides: Sides, value: number): Sides;
declare function inline(value: number): Sides;
declare function inline(sides: Sides, value: number): Sides;
declare function block(value: number): Sides;
declare function block(sides: Sides, value: number): Sides;
declare function left(value: number): Sides;
declare function left(sides: Sides, value: number): Sides;
declare function right(value: number): Sides;
declare function right(sides: Sides, value: number): Sides;
declare function top(value: number): Sides;
declare function top(sides: Sides, value: number): Sides;
declare function bottom(value: number): Sides;
declare function bottom(sides: Sides, value: number): Sides;

declare function angle(degrees: number): Vector2;
declare function toTop(): Vector2;
declare function toBottom(): Vector2;
declare function toLeft(): Vector2;
declare function toRight(): Vector2;
declare function toTopLeft(): Vector2;
declare function toTopRight(): Vector2;
declare function toBottomLeft(): Vector2;
declare function toBottomRight(): Vector2;
