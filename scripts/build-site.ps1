param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$DataPath = Join-Path $Root "data\site.json"
$OutputPath = Join-Path $Root "public\index.html"
$PublicPath = Join-Path $Root "public"

function Encode-Html {
  param([AllowNull()][object]$Value)
  return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-ModuleAttribute {
  param(
    [string]$Line,
    [string]$Name
  )

  $match = [regex]::Match($Line, "$Name=""([^""]*)""")
  if ($match.Success) {
    return $match.Groups[1].Value
  }
  return ""
}

function Render-RichText {
  param([AllowNull()][object]$Text)

  $lines = ([string]$Text).Replace("`r`n", "`n").Replace("`r", "`n").Split("`n")
  $html = @()
  $paragraph = @()

  foreach ($line in $lines) {
    $trimmed = $line.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmed)) {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      continue
    }

    if ($trimmed -match '^\[bouton ') {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      $text = Get-ModuleAttribute $trimmed "texte"
      $link = Get-ModuleAttribute $trimmed "lien"
      if ([string]::IsNullOrWhiteSpace($text)) { $text = "En savoir plus" }
      if ([string]::IsNullOrWhiteSpace($link)) { $link = "#" }
      $html += "          <p class=""module-button-wrap""><a class=""module-button"" href=""$(Encode-Html $link)"">$(Encode-Html $text)</a></p>"
      continue
    }

    if ($trimmed -match '^\[lien ') {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      $text = Get-ModuleAttribute $trimmed "texte"
      $url = Get-ModuleAttribute $trimmed "url"
      if ([string]::IsNullOrWhiteSpace($text)) { $text = "Lire la suite" }
      if ([string]::IsNullOrWhiteSpace($url)) { $url = "#" }
      $html += "          <p><a class=""module-link"" href=""$(Encode-Html $url)"">$(Encode-Html $text)</a></p>"
      continue
    }

    if ($trimmed -match '^\[image ') {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      $source = Get-ModuleAttribute $trimmed "source"
      $alt = Get-ModuleAttribute $trimmed "alt"
      $caption = Get-ModuleAttribute $trimmed "legende"
      $link = Get-ModuleAttribute $trimmed "lien"
      if ([string]::IsNullOrWhiteSpace($source)) { $source = "images/mon-image.jpg" }
      $captionHtml = ""
      if (-not [string]::IsNullOrWhiteSpace($caption)) {
        $captionHtml = "<figcaption>$(Encode-Html $caption)</figcaption>"
      }
      $imageHtml = "<img src=""$(Encode-Html $source)"" alt=""$(Encode-Html $alt)"">"
      if (-not [string]::IsNullOrWhiteSpace($link)) {
        $imageHtml = "<a href=""$(Encode-Html $link)"">$imageHtml</a>"
      }
      $html += "          <figure class=""module-image"">$imageHtml$captionHtml</figure>"
      continue
    }

    if ($trimmed -match '^\[encart ') {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      $text = Get-ModuleAttribute $trimmed "texte"
      $html += "          <aside class=""module-box"">$(Encode-Html $text)</aside>"
      continue
    }

    if ($trimmed -match '^\[citation ') {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      $text = Get-ModuleAttribute $trimmed "texte"
      $source = Get-ModuleAttribute $trimmed "source"
      $sourceHtml = ""
      if (-not [string]::IsNullOrWhiteSpace($source)) {
        $sourceHtml = "<cite>$(Encode-Html $source)</cite>"
      }
      $html += "          <blockquote class=""module-quote""><p>$(Encode-Html $text)</p>$sourceHtml</blockquote>"
      continue
    }

    if ($trimmed -eq "[separateur]") {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      $html += "          <hr class=""module-separator"">"
      continue
    }

    if ($trimmed -match '^\[question ') {
      if ($paragraph.Count -gt 0) {
        $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
        $html += "          <p>$content</p>"
        $paragraph = @()
      }
      $title = Get-ModuleAttribute $trimmed "titre"
      $response = Get-ModuleAttribute $trimmed "reponse"
      $html += "          <details class=""module-question"" open><summary>$(Encode-Html $title)</summary><p>$(Encode-Html $response)</p></details>"
      continue
    }

    $paragraph += $line
  }

  if ($paragraph.Count -gt 0) {
    $content = ($paragraph | ForEach-Object { Encode-Html $_ }) -join "<br>"
    $html += "          <p>$content</p>"
  }
  return ($html -join "`n")
}

function Render-Paragraphs {
  param([object[]]$Paragraphs)

  $html = @()
  foreach ($paragraph in $Paragraphs) {
    if (-not [string]::IsNullOrWhiteSpace([string]$paragraph)) {
      $html += Render-RichText $paragraph
    }
  }
  return ($html -join "`n")
}

function Render-Navigation {
  param(
    [object[]]$Items,
    [object[]]$Pages = @(),
    [string]$HomePrefix = ""
  )

  $html = @()
  foreach ($item in $Items) {
    $href = [string]$item.href
    if ($href.StartsWith("#")) {
      $href = "$HomePrefix$href"
    }
    $html += "        <a href=""$(Encode-Html $href)"">$(Encode-Html $item.label)</a>"
  }
  foreach ($page in $Pages) {
    if (-not [string]::IsNullOrWhiteSpace([string]$page.title) -and -not [string]::IsNullOrWhiteSpace([string]$page.slug)) {
      $html += "        <a href=""$(Encode-Html $page.slug).html"">$(Encode-Html $page.title)</a>"
    }
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
$(Render-RichText $card.text)
        </article>
"@
  }
  return ($html -join "`n")
}

function Get-BlockWidthClass {
  param([AllowNull()][object]$Section)

  if ([int]$Section.width -eq 50) {
    return " content-block-half"
  }
  return ""
}

function Render-PageSections {
  param([object[]]$Sections)

  $html = @()
  foreach ($section in $Sections) {
    $widthClass = Get-BlockWidthClass $section
    if ($section.type -eq "image") {
      $captionHtml = ""
      if (-not [string]::IsNullOrWhiteSpace([string]$section.caption)) {
        $captionHtml = "<figcaption>$(Encode-Html $section.caption)</figcaption>"
      }

      if (-not [string]::IsNullOrWhiteSpace([string]$section.source)) {
        $imageHtml = "<img src=""$(Encode-Html $section.source)"" alt=""$(Encode-Html $section.alt)"">"
        if (-not [string]::IsNullOrWhiteSpace([string]$section.link)) {
          $imageHtml = "<a href=""$(Encode-Html $section.link)"">$imageHtml</a>"
        }
        $html += @"
        <figure class="content-block module-image$widthClass">
          $imageHtml
          $captionHtml
        </figure>
"@
      }
      continue
    }

    if ($section.type -eq "link") {
      $text = [string]$section.text
      $url = [string]$section.url
      if ([string]::IsNullOrWhiteSpace($text)) { $text = "Lire la suite" }
      if ([string]::IsNullOrWhiteSpace($url)) { $url = "#" }

      $html += @"
        <article class="content-block$widthClass">
          <p><a class="module-link" href="$(Encode-Html $url)">$(Encode-Html $text)</a></p>
        </article>
"@
      continue
    }

    $html += @"
        <article class="content-block$widthClass">
          <h3>$(Encode-Html $section.title)</h3>
$(Render-RichText $section.text)
        </article>
"@
  }
  return ($html -join "`n")
}

function Render-PageFile {
  param(
    [object]$Page,
    [object]$Data,
    [string]$Navigation,
    [string]$OutputDirectory
  )

  $sections = Render-PageSections $Page.sections
  $pageTitle = "$(Encode-Html $Page.title) - $(Encode-Html $Data.site.name)"
  $outputFile = Join-Path $OutputDirectory "$($Page.slug).html"

  $html = @"
<!DOCTYPE html>
<html lang="fr">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$pageTitle</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
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
    .container { max-width: 980px; margin: 0 auto; padding: 0 2rem; }
    header .container {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 1.5rem;
    }
    h1 { font-size: 1.75rem; color: #71459a; font-weight: 700; }
    h1 a { color: inherit; text-decoration: none; }
    nav { display: flex; flex-wrap: wrap; gap: 1.5rem; justify-content: flex-end; }
    nav a {
      color: #71459a;
      text-decoration: none;
      font-size: 0.95rem;
      transition: color 0.2s ease;
      font-weight: 600;
    }
    nav a:hover { color: #476b5b; }
    .page-hero {
      padding: 5rem 2rem 3.5rem;
      background: #eef4ef;
      text-align: center;
    }
    .page-hero h2 {
      max-width: 820px;
      margin: 0 auto 1rem;
      color: #476b5b;
      font-size: clamp(2.2rem, 6vw, 4rem);
      line-height: 1.05;
      font-weight: 850;
    }
    .page-hero p {
      max-width: 720px;
      margin: 0 auto;
      color: #36483e;
      font-size: 1.08rem;
    }
    .page-content { padding: 4rem 0; background: #fff; }
    .content-layout {
      display: flex;
      flex-wrap: wrap;
      gap: 0 2rem;
      align-items: flex-start;
    }
    .content-block {
      width: 100%;
      padding: 1.5rem 0;
      border-bottom: 1px solid #eadff1;
    }
    .content-block-half {
      width: calc(50% - 1rem);
    }
    .content-block:first-child { padding-top: 0; }
    .content-block h3 {
      color: #5d347f;
      font-size: 1.35rem;
      margin-bottom: 0.65rem;
    }
    .content-block p { color: #54405e; font-size: 1.02rem; }
    .module-button-wrap { margin-top: 1rem; }
    .module-button {
      display: inline-flex;
      align-items: center;
      min-height: 44px;
      padding: 0.7rem 1rem;
      border-radius: 8px;
      background: #71459a;
      color: #fff;
      text-decoration: none;
      font-weight: 750;
      box-shadow: 0 10px 24px rgba(113, 69, 154, 0.18);
    }
    .module-link {
      color: #71459a;
      font-weight: 750;
      text-decoration-thickness: 2px;
      text-underline-offset: 0.18em;
    }
    .module-image {
      margin: 1.2rem 0;
    }
    .module-image img {
      width: 100%;
      max-height: 520px;
      object-fit: cover;
      border-radius: 8px;
      display: block;
      box-shadow: 0 12px 34px rgba(53, 33, 63, 0.12);
    }
    .module-image figcaption {
      margin-top: 0.45rem;
      color: #756a7c;
      font-size: 0.92rem;
      text-align: center;
    }
    .module-box {
      margin: 1rem 0;
      padding: 1rem;
      border: 1px solid #d8e5dc;
      border-radius: 8px;
      background: #eef4ef;
      color: #36483e;
      font-weight: 600;
    }
    .module-quote {
      margin: 1rem 0;
      padding: 0.3rem 0 0.3rem 1rem;
      border-left: 4px solid #71459a;
      color: #432a4f;
    }
    .module-quote p { font-size: 1.08rem; font-weight: 650; }
    .module-quote cite {
      display: block;
      margin-top: 0.4rem;
      color: #756a7c;
      font-style: normal;
    }
    .module-separator {
      margin: 1.6rem 0;
      border: 0;
      border-top: 1px solid #eadff1;
    }
    .module-question {
      margin: 1rem 0;
      padding: 1rem;
      border: 1px solid #eadff1;
      border-radius: 8px;
      background: #faf8fb;
    }
    .module-question summary {
      cursor: pointer;
      color: #5d347f;
      font-weight: 800;
    }
    .module-question p { margin-top: 0.65rem; }
    .cta-section {
      padding: 3.5rem 2rem;
      background: #f2e9f6;
      text-align: center;
    }
    .cta-section p {
      max-width: 680px;
      margin: 0 auto;
      color: #432a4f;
      font-size: 1.08rem;
      font-weight: 650;
    }
    footer {
      background: #35213f;
      padding: 2.5rem 2rem;
      text-align: center;
      color: #f8f5fb;
      font-size: 0.92rem;
    }
    footer p { margin-bottom: 0.4rem; }
    @media (max-width: 768px) {
      header .container { align-items: flex-start; flex-direction: column; }
      nav { justify-content: flex-start; }
      .container { padding: 0 1.25rem; }
      .page-hero { padding: 3.5rem 1.25rem 2.5rem; }
      .content-layout { display: block; }
      .content-block,
      .content-block-half { width: 100%; }
    }
  </style>
</head>

<body>
  <header>
    <div class="container">
      <h1><a href="index.html">$(Encode-Html $Data.site.name)</a></h1>
      <nav>
$Navigation
      </nav>
    </div>
  </header>

  <main>
    <section class="page-hero">
      <h2>$(Encode-Html $Page.title)</h2>
      <p>$(Encode-Html $Page.intro)</p>
    </section>

    <section class="page-content">
      <div class="container content-layout">
$sections
      </div>
    </section>

    <section class="cta-section">
      <p>$(Encode-Html $Page.callToAction)</p>
    </section>
  </main>

  <footer>
    <p>$(Encode-Html $Data.footer.copyright)</p>
    <p>$(Encode-Html $Data.footer.text)</p>
  </footer>
</body>

</html>
"@

  Set-Content -LiteralPath $outputFile -Value $html -Encoding UTF8
}

$data = Get-Content -Raw -Encoding UTF8 -LiteralPath $DataPath | ConvertFrom-Json

if ($null -eq $data.pages) {
  $data | Add-Member -NotePropertyName "pages" -NotePropertyValue @()
}

$navigation = Render-Navigation $data.navigation $data.pages
$pageNavigation = Render-Navigation $data.navigation $data.pages "index.html"
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

    .module-button-wrap {
      margin-top: 1rem;
    }

    .module-button {
      display: inline-flex;
      align-items: center;
      min-height: 44px;
      padding: 0.7rem 1rem;
      border-radius: 8px;
      background: #71459a;
      color: #fff;
      text-decoration: none;
      font-weight: 750;
      box-shadow: 0 10px 24px rgba(113, 69, 154, 0.18);
    }

    .module-link {
      color: #71459a;
      font-weight: 750;
      text-decoration-thickness: 2px;
      text-underline-offset: 0.18em;
    }

    .module-image {
      margin: 1.2rem 0;
    }

    .module-image img {
      width: 100%;
      max-height: 520px;
      object-fit: cover;
      border-radius: 8px;
      display: block;
      box-shadow: 0 12px 34px rgba(53, 33, 63, 0.12);
    }

    .module-image figcaption {
      margin-top: 0.45rem;
      color: #756a7c;
      font-size: 0.92rem;
      text-align: center;
    }

    .module-box {
      margin: 1rem 0;
      padding: 1rem;
      border: 1px solid #d8e5dc;
      border-radius: 8px;
      background: #eef4ef;
      color: #36483e;
      font-weight: 600;
    }

    .module-quote {
      margin: 1rem 0;
      padding: 0.3rem 0 0.3rem 1rem;
      border-left: 4px solid #71459a;
      color: #432a4f;
    }

    .module-quote p {
      font-size: 1.08rem;
      font-weight: 650;
    }

    .module-quote cite {
      display: block;
      margin-top: 0.4rem;
      color: #756a7c;
      font-style: normal;
    }

    .module-separator {
      margin: 1.6rem 0;
      border: 0;
      border-top: 1px solid #eadff1;
    }

    .module-question {
      margin: 1rem 0;
      padding: 1rem;
      border: 1px solid #eadff1;
      border-radius: 8px;
      background: #faf8fb;
    }

    .module-question summary {
      cursor: pointer;
      color: #5d347f;
      font-weight: 800;
    }

    .module-question p {
      margin-top: 0.65rem;
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
      <div class="hero-bg" aria-hidden="true" data-src="$(Encode-Html $data.hero.image)"></div>
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

  <script src="js/images.js?v=1"></script>
</body>

</html>
"@

Set-Content -LiteralPath $OutputPath -Value $html -Encoding UTF8
foreach ($page in $data.pages) {
  if (-not [string]::IsNullOrWhiteSpace([string]$page.slug)) {
    Render-PageFile $page $data $pageNavigation $PublicPath
  }
}
Write-Host "Site généré dans public/index.html"
