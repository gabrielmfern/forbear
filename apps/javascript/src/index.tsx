console.log("hey, this is nodejs, believe it or not!");

let fps = 0;
let frames = 0;
let last = performance.now();

setRenderFunction(() => {
  frames += 1;
  const now = performance.now();
  if (now - last >= 1000) {
    fps = frames;
    frames = 0;
    last = now;
  }

  <element
    background={color(rgb(255, 0, 255))}
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
    </element>
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
  // open({
  //   width: fixed(500),
  //   height: fixed(500),
  //   background: color(rgb(255, 0, 255)),
  //   color: rgb(255, 255, 255),
  // })
  //
  // text("hello lisa");
  //
  // close();
});
