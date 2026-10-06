console.log("hey, this is nodejs, believe it or not!");

setRenderFunction(() => {
  <element 
    width={fixed(500)} 
    height={fixed(500)} 
    background={color(rgb(255, 0, 255))} 
    color={rgb(255, 255, 255)}
    fontSize={64}
  >
    hello lisa!!!!!!!!!!!
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
