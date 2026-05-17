param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$DataPath = Join-Path $Root "data\site.json"
$OutputPath = Join-Path $Root "public\index.html"

function Encode-Html {
  param([AllowNull()][object]$Value)
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Render-Paragraphs {
  param([object[]]$Paragraphs)

  $html = @()
  foreach ($paragraph in $Paragraphs) {
    if (-not [string]::IsNullOrWhiteSpace([string]$paragraph)) {
      $html += "        <p>$(Encode-Html $paragraph)</p>"
    }
  }
  return ($html -join "`n")
}

function Render-Navigation {
  param([object[]]$Items)

  $html = @()
  foreach ($item in $Items) {
    $html += "        <a href=""$(Encode-Html $item.href)"">$(Encode-Html $item.label)</a>"
  }
  return ($html -join "`n")
}

function Render-Cards {
  param([object[]]$Cards)

  $html = @()
  foreach ($card in $Cards) {
    $html += @"
        <article class="philosophy-card">
          <h4>$(Encode-Html $card.title)</h4>
          <p>$(Encode-Html $card.text)</p>
        </article>
"@
  }
  return ($html -join "`n")
}

$data = Get-Content -Raw -Encoding UTF8 -LiteralPath $DataPath | ConvertFrom-Json

$navigation = Render-Navigation $data.navigation
$heroParagraphs = Render-Paragraphs $data.hero.paragraphs
$cards = Render-Cards $data.philosophy.cards
$contactParagraphs = Render-Paragraphs $data.contact.paragraphs

$html = @"
<!DOCTYPE html>
<html lang="fr">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$(Encode-Html $data.site.title)</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', sans-serif;
      background: #f8f5fb;
      color: #35213f;
      line-height: 1.7;
      min-height: 100vh;
    }

    header {
      background: rgba(255, 255, 255, 0.94);
      border-bottom: 1px solid #eadff1;
      padding: 1.2rem 0;
      position: sticky;
      top: 0;
      z-index: 100;
      backdrop-filter: blur(14px);
    }

    .container {
      max-width: 1080px;
      margin: 0 auto;
      padding: 0 2rem;
    }

    header .container {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 1.5rem;
    }

    h1 {
      font-size: 1.75rem;
      color: #71459a;
      font-weight: 700;
    }

    nav {
      display: flex;
      flex-wrap: wrap;
      gap: 1.5rem;
      justify-content: flex-end;
    }

    nav a {
      color: #71459a;
      text-decoration: none;
      font-size: 0.95rem;
      transition: color 0.2s ease;
      font-weight: 600;
    }

    nav a:hover {
      color: #476b5b;
    }

    .hero {
      position: relative;
      min-height: 64vh;
      padding: 4.5rem 2rem 4rem;
      display: grid;
      grid-template-columns: minmax(0, 1.05fr) minmax(260px, 0.95fr);
      gap: 3rem;
      align-items: center;
      overflow: hidden;
      background: #f2e9f6;
    }

    .hero-bg {
      position: absolute;
      inset: 0;
      background-image: url('$(Encode-Html $data.hero.image)');
      background-size: cover;
      background-position: center right;
      background-repeat: no-repeat;
      filter: blur(16px) brightness(0.62);
      transform: scale(1.08);
      z-index: 0;
      pointer-events: none;
    }

    .hero::after {
      content: "";
      position: absolute;
      inset: 0;
      background: linear-gradient(90deg, rgba(248, 245, 251, 0.92), rgba(248, 245, 251, 0.72), rgba(248, 245, 251, 0.22));
      z-index: 1;
    }

    .hero-content {
      position: relative;
      z-index: 2;
      max-width: 670px;
    }

    .hero-content h2 {
      font-size: clamp(2.1rem, 6vw, 4.8rem);
      color: #5d347f;
      margin-bottom: 1.2rem;
      font-weight: 800;
      line-height: 1.04;
    }

    .hero-content p {
      font-size: 1.05rem;
      color: #432a4f;
      margin-bottom: 1rem;
      max-width: 620px;
    }

    .hero-image {
      position: relative;
      z-index: 3;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .hero-image img {
      width: min(92%, 430px);
      height: auto;
      object-fit: cover;
      object-position: center right;
      border-radius: 8px;
      box-shadow: 0 18px 55px rgba(45, 33, 63, 0.22);
      display: block;
    }

    .philosophy {
      padding: 5rem 2rem;
      background: #fff;
    }

    .philosophy h3,
    .cta-section h3 {
      text-align: center;
      font-size: 2rem;
      color: #35213f;
      margin-bottom: 2.5rem;
      font-weight: 800;
    }

    .philosophy-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 1.25rem;
    }

    .philosophy-card {
      padding: 1.5rem;
      background: #faf8fb;
      border-radius: 8px;
      border: 1px solid #eadff1;
      transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
    }

    .philosophy-card:hover {
      border-color: #b7c8bd;
      box-shadow: 0 12px 30px rgba(53, 33, 63, 0.08);
      transform: translateY(-3px);
    }

    .philosophy-card h4 {
      color: #5d347f;
      margin-bottom: 0.7rem;
      font-size: 1.12rem;
      font-weight: 750;
    }

    .philosophy-card p {
      color: #54405e;
      font-size: 0.96rem;
    }

    .cta-section {
      padding: 4.5rem 2rem;
      background: #eef4ef;
      text-align: center;
    }

    .cta-section h3 {
      color: #476b5b;
      margin-bottom: 1.2rem;
    }

    .cta-section p {
      font-size: 1.04rem;
      color: #36483e;
      margin: 0 auto 1rem;
      max-width: 650px;
    }

    .site-signature {
      text-align: center;
      padding: 2.5rem 2rem;
      color: #54405e;
      font-size: 1.02rem;
      background: #fff;
    }

    footer {
      background: #35213f;
      padding: 2.5rem 2rem;
      text-align: center;
      color: #f8f5fb;
      font-size: 0.92rem;
    }

    footer p {
      margin-bottom: 0.4rem;
    }

    @media (max-width: 768px) {
      header .container {
        align-items: flex-start;
        flex-direction: column;
      }

      nav {
        justify-content: flex-start;
      }

      .hero {
        grid-template-columns: 1fr;
        padding: 3rem 1.25rem;
      }

      .hero::after {
        background: rgba(248, 245, 251, 0.82);
      }

      .hero-image img {
        width: min(72%, 320px);
      }

      .philosophy,
      .cta-section {
        padding-left: 1.25rem;
        padding-right: 1.25rem;
      }
    }
  </style>
</head>

<body>
  <header>
    <div class="container">
      <h1>$(Encode-Html $data.site.name)</h1>
      <nav>
$navigation
      </nav>
    </div>
  </header>

  <main>
    <section class="hero" aria-label="Bandeau principal">
      <div class="hero-bg" aria-hidden="true"></div>
      <div class="hero-content">
        <h2>$(Encode-Html $data.hero.title)</h2>
$heroParagraphs
      </div>
      <div class="hero-image">
        <img src="$(Encode-Html $data.hero.image)" alt="$(Encode-Html $data.hero.imageAlt)" loading="lazy">
      </div>
    </section>

    <section class="philosophy" id="philosophie">
      <div class="container">
        <h3>$(Encode-Html $data.philosophy.title)</h3>
        <div class="philosophy-grid">
$cards
        </div>
      </div>
    </section>

    <section class="cta-section" id="contact">
      <h3>$(Encode-Html $data.contact.title)</h3>
$contactParagraphs
    </section>

    <div class="site-signature">
      $(Encode-Html $data.site.name) - $(Encode-Html $data.site.tagline).
    </div>
  </main>

  <footer>
    <p>$(Encode-Html $data.footer.copyright)</p>
    <p>$(Encode-Html $data.footer.text)</p>
  </footer>
</body>

</html>
"@

Set-Content -LiteralPath $OutputPath -Value $html -Encoding UTF8
Write-Host "Site généré dans public/index.html"
