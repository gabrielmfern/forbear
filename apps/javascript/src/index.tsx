console.log("hey, this is nodejs, believe it or not!");

let fps = 0;
let frames = 0;
let last = performance.now();
let previous = last;
let frameSum = 0;
let frameMax = 0;
let averageMs = 0;
let maxMs = 0;
let frame = 0;

setRenderFunction(() => {
  const now = performance.now();
  const delta = now - previous;
  previous = now;
  frame += 1;
  frames += 1;
  frameSum += delta;
  frameMax = Math.max(frameMax, delta);
  if (now - last >= 1000) {
    fps = frames;
    averageMs = frameSum / frames;
    maxMs = frameMax;
    frames = 0;
    frameSum = 0;
    frameMax = 0;
    last = now;
  }

  <element
    background={color(rgb(255, 0, 255))}
    margin={top(100)}
    padding={block(inline(50), 30)}
    yJustification="center"
  >
    <element
      placement={fixed([10, 10])}
      zIndex={10}
      background={color(rgba(0, 0, 0, 0.9))}
      fontSize={16}
      textWrapping="none"
      minWidth={152}
      padding={all(4)}
      borderRadius={4}
      color={rgb(255, 255, 0)}
      direction="vertical"
    >
      <element width={grow(1)}>
        FPS:
        <element width={grow(1)} />
        {`${fps}`}
      </element>
      <element width={grow(1)}>
        avg:
        <element width={grow(1)} />
        {`${averageMs.toFixed(1)} ms`}
      </element>
      <element width={grow(1)}>
        max:
        <element width={grow(1)} />
        {`${maxMs.toFixed(1)} ms`}
      </element>
    </element>
    <element
      placement={fixed([(frame * 4) % 760, 540])}
      zIndex={10}
      width={fixed(40)}
      height={fixed(40)}
      background={color(rgb(255, 255, 0))}
    />
    root node
    <element 
      width={fixed(60)} 
      height={fixed(75)} 
      background={color(rgb(0, 0, 255))} 
      margin={left(50)} 
      xJustification="center"
      yJustification="center"
    >
      first node
    </element>
    <element 
      width={fixed(60)} 
      height={fixed(75)} 
      background={color(rgb(0, 255, 0))} 
      xJustification="center"
      yJustification="center"
    >
      second node
    </element>
    <element 
      width={fixed(60)} 
      height={fixed(75)} 
      background={color(rgb(255, 0, 0))} 
      margin={right(50)}
      xJustification="center"
      yJustification="center"
    >
      third node 
    </element>
    hello lisa
  </element>;
});
