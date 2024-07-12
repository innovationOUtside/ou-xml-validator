function resizeExpandableCodeIframes() {
  const iframes = document.getElementsByName("expandable-code-iframe");
  iframes.forEach((iframe) => {
    iframe.style.height =
      iframe.contentWindow.document.documentElement.scrollHeight + 20 + "px";
    iframe.style.width =
      iframe.contentWindow.document.documentElement.scrollWidth + 20 + "px";
  });

}
