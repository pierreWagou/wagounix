// Randomly pick a background image on each page load.
const images = ["bridge.jpg", "city.jpg", "dock.jpg", "hood.jpg", "ocean.jpg", "river.jpg", "street.jpg"];
const pick = images[Math.floor(Math.random() * images.length)];
const bgEl = document.getElementById("background");
if (bgEl) {
  bgEl.style.backgroundImage = "url('/bg/" + pick + "')";
}
