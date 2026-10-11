console.log("hey, this is nodejs, believe it or not!");

let fps = 0;
let frames = 0;
let last = performance.now();
let previous = last;
let frameSum = 0;
let frameMax = 0;
let averageMs = 0;
let maxMs = 0;

setRenderFunction(() => {
  const now = performance.now();
  const delta = now - previous;
  previous = now;
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

  const seconds = now / 1000;
  const wave = (speed: number, phase: number) => (Math.sin(seconds * speed + phase) + 1) / 2;
  const bars = 8 + Math.floor(40 * wave(0.4, 0));
  const phase = (seconds * 2.3) % (Math.PI * 2);

  <element
    width={grow()}
    height={grow()}
    background={color(rgb(28, 31, 35))}
    color={rgb(174, 184, 196)}
    fontSize={14}
    padding={all(16)}
    direction="vertical"
  >
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
        <element width={grow()}>
          avg:
          <element width={grow()} />
          {`${averageMs.toFixed(1)} ms`}
        </element>
        <element width={grow()}>
          max:
          <element width={grow()} />
          {`${maxMs.toFixed(1)} ms`}
        </element>
      </element>
    </element>

    <element width={grow()} height={grow()} margin={top(16)}>
      <element
        width={fixed(96 + 180 * wave(1.1, 0))}
        height={grow()}
        background={color(rgb(17, 19, 22))}
        padding={all(8)}
        direction="vertical"
        margin={right(16)}
      >
        {["Inbox", "Sent mail", "Drafts and notes", "Everything else"].map((folder) => (
          <element
            width={grow()}
            background={color(rgb(44, 51, 59))}
            color={rgb(255, 255, 255)}
            padding={all(8)}
            margin={bottom(8)}
          >
            {folder}
          </element>
        ))}
      </element>

      <element width={grow()} height={grow()} margin={left(16)} direction="vertical">
        <element width={grow()} background={color(rgb(17, 19, 22))} padding={all(12)}>
          Every frame, this whole window is laid out from scratch. The sidebar changes its width, so this paragraph has to wrap its words again, the cards below have to share what is left, and every bar has to find its new place. Nothing here is a transform, all of it is layout.
        </element>
        <element width={grow()} margin={top(16)}>
          {[
            ["fit", "A node is as big as its children."],
            ["grow", "A node takes a share of the space that is left."],
            ["shrink", "A node gives space back when there is not enough."],
          ].map(([title, description], index) => (
            <element
              width={grow(1 + 3 * wave(0.9, index * 2.1))}
              height={grow()}
              background={color(rgb(44, 51, 59))}
              padding={all(10)}
              margin={right(index === 2 ? 0 : 8)}
            >
              <element width={grow()} direction="vertical">
                <element color={rgb(184, 163, 106)} fontSize={18}>
                  {title}
                </element>
                {description}
              </element>
            </element>
          ))}
        </element>
        <element height={grow()} />
        <element margin={top(16)} color={rgb(255, 255, 255)} direction="vertical">
          <element>
            {`height(x) = 61 + 45 · sin(0.35x + ${phase.toFixed(2)}), x from 0 to ${bars - 1}`}
          </element>
          <element>
            ... and while all of this layouting is happening, here's the above function graphed
          </element>
        </element>
        <element width={grow()} height={fixed(106)} margin={bottom(top(8), 16)} yJustification="end">
          {Array.from({ length: bars }, (_, index) => (
            <element
              width={grow()}
              height={fixed(61 + 45 * Math.sin(0.35 * index + phase))}
              background={color(rgb(184, 163, 106))}
              margin={right(index === bars - 1 ? 0 : 3)}
            />
          ))}
        </element>
      </element>
    </element>
  </element>;
});
