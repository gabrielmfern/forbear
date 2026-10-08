console.log("hey, this is nodejs, believe it or not!");

setRenderFunction(() => {
  <element
    background={color(rgb(255, 0, 255))}
    padding={block(inline(50), 30)}
    yJustification="center"
  >
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
