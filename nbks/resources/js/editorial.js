function nbs(selector = "[data-nb]", heading = "<h3>Notes</h3>") {
  const container = document.createElement("div");
  let headings = [];

  function hashLinkCheck(hashLink) {
    let hashLinkChecks = 0;
    const hashLinkChecker = setInterval((checksLimit = 2) => {
      let div = document.getElementById(
        hashLink.substring(hashLink.indexOf("#") + 1)
      );
      if (div) {
        div.scrollIntoView();
        clearInterval(hashLinkChecker);
      }
      if (++hashLinkChecks >= checksLimit && !div)
        clearInterval(hashLinkChecker);
    }, 100);
  }

  function observed() {
    let nbNum = 0;
    const h = Array.from(document.querySelectorAll(selector));
    if (h.length !== headings.length || h.some((h, i) => headings[i] !== h)) {
      headings = h;
      container.innerHTML = heading;
      const inner = document.createElement("div");
      headings.forEach((h) => {
        h.innerHTML = `<a class=nb href=#_${h.dataset.nb}>[${++nbNum}]</a>`;
        h.onclick = (e) => {
          e.preventDefault();
          hashLinkCheck(e.target.href);
        };
        const p = document.createElement("p");
        p.className = "nb";
        p.id = `_${h.dataset.nb}`;
        const atag = document.createElement("a");
        atag.href = `#${h.id}`;
        atag.textContent = `${nbNum}.`;
        atag.onclick = (e) => { e.preventDefault(); h.scrollIntoView(); };
        const noteEl = document.getElementById(h.dataset.nb);
        p.appendChild(atag);
        p.append(" " + (noteEl ? noteEl.innerHTML : ""));
        inner.appendChild(p);
      });
      container.appendChild(inner);
    }
  }

  const observer = new MutationObserver(observed);
  observer.observe(document.body, { childList: true, subtree: true });
  observed();
  return container;
}
export { nbs };