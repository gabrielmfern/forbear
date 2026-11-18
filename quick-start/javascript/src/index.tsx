let frames = 0;
let fps = 0;
let last = performance.now();
let counter = 0;

const FpsMonitor = () => {
  frames += 1;
  const now = performance.now();
  if (now - last >= 1000) {
    fps = frames;
    frames = 0;
    last = now;
  }

  <element width={grow()} yJustification="center">
    <element fontSize={28} color={rgb(255, 255, 255)}>
      forbear
    </element>
    <element width={grow()} />
    <element
      background={color(rgb(17, 19, 22))}
      textWrapping="none"
      minWidth={152}
      padding={all(8)}
      color={rgb(184, 163, 106)}
      direction="vertical"
    >
      <element width={grow()}>
        FPS:
        <element width={grow()} />
        {`${fps}`}
      </element>
    </element>
  </element>;
};

const Counter = () => {
  text("PLUS (+): increases the counter by one");
  text("MINUS (-): decreases the counter by one");
  // Since this is immediate mode, there's no need for callbacks or event handlers,
  // we can simply check for the key being down through an if-statement.
  if (onKeyDown("+")) {
    counter += 1;
  } else if (onKeyDown("-")) {
    counter -= 1;
  }

  text("LEFT CLICK in the button: increases the counter by one");
  text("RIGHT CLICK in the button: decreases the counter by one");
  // <element> compiles to open() and close() calls, so writing them directly
  // lets us check for clicks while the button is the open element.
  open({
    background: color(rgb(44, 49, 56)),
    color: rgb(230, 234, 239),
    borderWidth: all(1),
    borderColor: rgb(66, 73, 82),
    borderRadius: 6,
    padding: inLine(block(8), 16),
    margin: block(8),
  }, "button");
  text("Click me");
  if (onClick("left")) {
    counter += 1;
  } else if (onClick("right")) {
    counter -= 1;
  }
  close();

  text({ fontSize: 32 }, `Count: ${counter}`);
};

setRenderFunction(() => {
  open({
    width: grow(),
    height: grow(),
    background: color(rgb(28, 31, 35)),
    color: rgb(174, 184, 196),
    fontSize: 14,
    padding: all(16),
    textWrapping: "character",
    direction: "vertical",
  }, "root");
  FpsMonitor();
  Counter();
  close();
});
