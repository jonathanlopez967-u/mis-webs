#!/usr/bin/perl
use strict; use warnings;
use MIME::Base64;

my $H = "C:/Users/Jonathan";
my $outdir = "$H/Desktop/WEB/_TODAS-MIS-WEBS";

# name | project root
my @projects = (
  ["azulaya-inmobiliaria",     "$H/Desktop/WEB/azulaya-inmobiliaria"],
  ["centro-rita-alonso",       "$H/Desktop/WEB/centrorita-web"],
  ["clinica-lopez-rodrigo",    "$H/Desktop/WEB/clinica-lopez-rodrigo"],
  ["clinica-marta-cabrera",    "$H/Desktop/WEB/clinica-marta-cabrera"],
  ["clinica-mercurio",         "$H/Desktop/WEB/clinica-mercurio"],
  ["clinica-pedro-infinito",   "$H/Desktop/WEB/clinica-pedro-infinito"],
  ["dental-carballo",          "$H/Desktop/WEB/dental-carballo"],
  ["dental-carrizal-premium",  "$H/Desktop/WEB/dental-carrizal-premium"],
  ["dgm-racing-chip",          "$H/Desktop/WEB/dgm-racing-chip"],
  ["dra-alomeran",             "$H/Desktop/WEB/dra-alomeran-web"],
  ["eva-peluqueros",           "$H/Desktop/WEB/eva-peluqueros"],
  ["fisioterapia-cristina",    "$H/Desktop/WEB/fisioterapia-cristina"],
  ["fisioterapia-med",         "$H/Desktop/WEB/fisioterapia-med"],
  ["gabinete-dental-carrizal", "$H/Desktop/WEB/gabinete-dental-carrizal"],
  ["instituto-rubi",           "$H/Desktop/WEB/instituto-rubi"],
  ["looal-dental",             "$H/Desktop/WEB/looal-dental-web"],
  ["sanchez-automocion",       "$H/Desktop/WEB/sanchez-automocion"],
  ["stylocel",                 "$H/Desktop/WEB/stylocel"],
  ["velvet-peluqueria",        "$H/Desktop/WEB/velvet-peluqueria"],
  ["web-nona",                 "$H/Desktop/WEB/web-nona"],
  ["yelitza-dental",           "$H/Desktop/WEB/yelitza-dental"],
  ["better-half-nutrition",    "$H/Desktop/WEB MARCA EMPRENDE FBA/better-half-nutrition"],
  ["emprende-fba",             "$H/Desktop/WEB MARCA EMPRENDE FBA/emprendefba-web"],
  ["neyral-home",              "$H/Desktop/WEB MARCA EMPRENDE FBA/neyralhome-web"],
  ["srmpets",                  "$H/Desktop/WEB MARCA EMPRENDE FBA/srmpets-web"],
  ["tecoverpro",               "$H/Desktop/WEB MARCA EMPRENDE FBA/tecoverpro-web"],
  ["centro-contrology",        "$H/.claude/centro-contrology"],
  ["controology",              "$H/.claude/controology"],
  ["multiservicios-gonzalez",  "$H/.claude/multiservicios-gonzalez"],
  ["ssg-fisioterapia",         "$H/.claude/ssg-fisioterapia"],
  ["taller-rpm",               "$H/.claude/taller-rpm"],
  ["equipo-gt",                "$H/.claude/equipo-gt"],
  ["fisio-yedra-premium",      "$H/Desktop/WEB/fisio-yedra-premium"],
  ["paula-mateos",             "$H/Desktop/WEB/paula-mateos-tattoo"],
);

my %MIME = (
  webp=>"image/webp", jpg=>"image/jpeg", jpeg=>"image/jpeg", png=>"image/png",
  svg=>"image/svg+xml", ico=>"image/x-icon", gif=>"image/gif", avif=>"image/avif",
);

sub slurp { my ($f)=@_; open my $fh,'<:raw',$f or return undef; local $/; my $d=<$fh>; close $fh; return $d; }

sub build_one {
  my ($name,$root)=@_;
  my $idx = "$root/index.html";
  my $html = slurp($idx);
  return (undef, "sin index.html") unless defined $html;

  # strip ?v=... cache busters after local refs (any suffix, not just digits)
  $html =~ s/(\.(?:css|js|webp|jpg|jpeg|png|svg|ico|gif|avif))\?[^"'()\s>]*/$1/gi;

  # inline local stylesheets
  $html =~ s{<link[^>]*rel="stylesheet"[^>]*href="(?!https?:)([^"?]+)"[^>]*>}{
      my $f = "$root/$1"; my $c = slurp($f); defined $c ? "<style>\n$c\n</style>" : $&;
  }ge;

  # inline local scripts
  $html =~ s{<script[^>]*src="(?!https?:)([^"?]+)"[^>]*>\s*</script>}{
      my $f = "$root/$1"; my $c = slurp($f); defined $c ? "<script>\n$c\n</script>" : $&;
  }ge;

  # collect asset paths (in HTML + now-inlined CSS/JS)
  my %seen;
  while ($html =~ m{((?:assets|img|images)/[A-Za-z0-9_\-./ ]+?\.(webp|jpg|jpeg|png|svg|ico|gif|avif))}gi) {
    $seen{$1} = lc($2);
  }
  my $embedded = 0; my $missing = 0;
  for my $path (keys %seen) {
    my $f = "$root/$path";
    my $data = slurp($f);
    if (!defined $data) { $missing++; next; }
    my $mime = $MIME{$seen{$path}} || "application/octet-stream";
    my $uri = "data:$mime;base64," . encode_base64($data, '');
    my $q = quotemeta($path);
    $html =~ s/\Q$path\E/$uri/g;
    $embedded++;
  }

  open my $o,'>:raw',"$outdir/$name.html" or return (undef, "no se pudo escribir");
  print $o $html; close $o;

  my ($title) = $html =~ m{<title>(.*?)</title>}s;
  $title //= $name;
  my $kb = int(length($html)/1024);
  return ($title, "OK ${kb}KB · $embedded img" . ($missing? " · $missing sin encontrar":""));
}

my @rows;
for my $p (@projects) {
  my ($name,$root) = @$p;
  my ($title,$status) = build_one($name,$root);
  printf "%-28s %s\n", $name, $status;
  push @rows, [$name, $title // $name] if defined $title;
}

# ---- gallery index ----
my $cards = "";
for my $r (sort { lc($a->[1]) cmp lc($b->[1]) } @rows) {
  my ($file,$title) = @$r;
  my $t = $title; $t =~ s/&/&amp;/g; $t =~ s/</&lt;/g;
  $cards .= qq{      <a class="card" href="$file.html" target="_blank" rel="noopener"><span class="dot"></span><h2>$t</h2><span class="go">Abrir &rarr;</span></a>\n};
}
my $n = scalar @rows;
my $gallery = <<"HTML";
<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mis webs — Jonathan López · Emprende FBA</title>
<style>
*{margin:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",system-ui,sans-serif;background:#0b0d10;color:#eef1f4;line-height:1.5;padding:clamp(1.4rem,5vw,4rem)}
header{max-width:1100px;margin:0 auto 2.6rem}
.kick{font-size:.72rem;letter-spacing:.28em;text-transform:uppercase;color:#5cc0ff;font-weight:700}
h1{font-size:clamp(1.9rem,5vw,3rem);font-weight:600;margin:.5rem 0 .4rem;letter-spacing:-.02em}
.sub{color:#93a0ad;max-width:56ch}
.grid{max-width:1100px;margin:0 auto;display:grid;gap:.9rem;grid-template-columns:1fr}
.card{display:flex;align-items:center;gap:1rem;padding:1.25rem 1.4rem;border:1px solid #1e252d;border-radius:14px;background:#12161b;transition:.35s cubic-bezier(.16,1,.3,1);text-decoration:none;color:inherit}
.card:hover{transform:translateY(-3px);border-color:#5cc0ff;background:#161c23}
.dot{width:9px;height:9px;border-radius:50%;background:#5cc0ff;flex:0 0 auto;box-shadow:0 0 12px #5cc0ff}
.card h2{font-size:1.06rem;font-weight:500;flex:1}
.go{color:#5cc0ff;font-size:.9rem;opacity:0;transition:.35s}
.card:hover .go{opacity:1}
footer{max-width:1100px;margin:3rem auto 0;color:#5a6672;font-size:.82rem;border-top:1px solid #1e252d;padding-top:1.4rem}
\@media(min-width:640px){.grid{grid-template-columns:1fr 1fr}}
\@media(min-width:1000px){.grid{grid-template-columns:1fr 1fr 1fr}}
</style></head><body>
<header>
  <p class="kick">Portfolio · Diseño web</p>
  <h1>Mis webs</h1>
  <p class="sub">$n webs premium listas para enseñar. Cada tarjeta abre la demo completa en una pestaña nueva. Todo funciona sin conexión salvo las tipografías.</p>
</header>
<main class="grid">
$cards</main>
<footer>Jonathan López · Emprende FBA — colección de demos autónomas.</footer>
</body></html>
HTML

open my $g,'>:raw',"$outdir/index.html" or die $!;
print $g $gallery; close $g;
print "\nGALLERY: $outdir/index.html  ($n webs)\n";
