/// <reference types="../adapters/javascript.d.ts"/>

console.log("hey, this is nodejs, believe it or not!");

setRenderFunction(() => {
  open({
    width: fixed(500),
    height: fixed(500),
    background: color(rgb(255, 0, 255)),
    color: rgb(255, 255, 255),
  })

  text("hello lisa");

  close();
});
