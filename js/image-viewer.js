(function () {
  const viewer = document.querySelector('.image-viewer');
  const viewerImage = viewer.querySelector('img');

  document.querySelector('article.blog-post').addEventListener('click', (event) => {
    const image = event.target;
    if (image.tagName !== 'IMG' || image.closest('a')) {
      return;
    }
    viewerImage.src = image.src;
    viewerImage.alt = image.alt;
    viewerImage.style.setProperty('--aspect-ratio', image.naturalWidth / image.naturalHeight);
    viewer.showModal();
  });

  // Clicks on the backdrop target the dialog itself, so anything but the image closes the viewer
  viewer.addEventListener('click', (event) => {
    if (event.target !== viewerImage) {
      viewer.close();
    }
  });
})();
