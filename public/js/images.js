document.addEventListener('DOMContentLoaded', () => {
  const mediaQuery = window.matchMedia('(max-width: 768px)');

  function getWebpPath(imagePath, isMobile) {
    const lastSlash = imagePath.lastIndexOf('/');
    const lastDot = imagePath.lastIndexOf('.');

    const dir = lastSlash >= 0 ? imagePath.substring(0, lastSlash + 1) : '';
    const stem = lastDot > lastSlash ? imagePath.substring(lastSlash + 1, lastDot) : imagePath.substring(lastSlash + 1);

    const subdir = isMobile ? 'mobile' : 'desktop';
    return dir + subdir + '/' + stem + '.webp';
  }

  // Transform <img> to <picture>
  document.querySelectorAll('img[src*="images/"]').forEach(img => {
    if (img.hasAttribute('data-no-webp')) return;

    const originalSrc = img.getAttribute('src');
    const isMobile = mediaQuery.matches;
    const mobileWebp = getWebpPath(originalSrc, true);
    const desktopWebp = getWebpPath(originalSrc, false);

    const picture = document.createElement('picture');

    const sourceDesktop = document.createElement('source');
    sourceDesktop.setAttribute('media', '(min-width: 769px)');
    sourceDesktop.setAttribute('srcset', desktopWebp);
    sourceDesktop.setAttribute('type', 'image/webp');
    picture.appendChild(sourceDesktop);

    const sourceMobile = document.createElement('source');
    sourceMobile.setAttribute('media', '(max-width: 768px)');
    sourceMobile.setAttribute('srcset', mobileWebp);
    sourceMobile.setAttribute('type', 'image/webp');
    picture.appendChild(sourceMobile);

    // Copy the original img and update its src to be the PNG fallback
    const newImg = img.cloneNode(true);
    newImg.removeAttribute('data-no-webp');
    picture.appendChild(newImg);

    img.replaceWith(picture);
  });

  // Handle background images on .hero-bg
  const heroBg = document.querySelector('.hero-bg');
  if (heroBg && heroBg.hasAttribute('data-src')) {
    const originalSrc = heroBg.getAttribute('data-src');

    function updateHeroBg() {
      const isMobile = window.matchMedia('(max-width: 768px)').matches;
      const webpPath = getWebpPath(originalSrc, isMobile);
      heroBg.style.backgroundImage = `url('${webpPath}')`;
    }

    updateHeroBg();
    mediaQuery.addEventListener('change', updateHeroBg);
  }
});
