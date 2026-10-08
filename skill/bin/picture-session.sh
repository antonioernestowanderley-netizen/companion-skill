#!/usr/bin/env bash
# Start a short picture-choice session — the self-portrait for little ones and anyone
# who answers best by choosing. A warm-up card, then N cards, least-answered first.
# Options are shuffled every time, so picking-by-position shows up in the summary.
# Usage: picture-session.sh <subject> [--lang en|pt|…] [--n 4] [--cards id,id] [--html]
#   --cards: ask these cards again (to confirm an emerging answer), instead of least-answered
#   default: prints a script for the grown-up to read and show
#   --html:  writes a big-tile, tap-to-choose page to data/picks/ and prints its path
set -euo pipefail
. "$(dirname "$0")/_lib.sh"

S=""; LG="en"; N=4; HTML=0; WANT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lang) LG="${2:?}"; shift 2 ;;
    --n)    N="${2:?}"; shift 2 ;;
    --html) HTML=1; shift ;;
    --cards) WANT="${2:?}"; shift 2 ;;
    -*)     die "unknown option $1" ;;
    *)      S="$1"; shift ;;
  esac
done
[ -n "$S" ] || die "usage: picture-session.sh <subject> [--lang en|pt] [--n 4] [--html]"
check_name "$S"
case "$N" in ''|*[!0-9]*) die "--n must be a number" ;; esac
[ "$N" -le 6 ] || die "--n: keep it to 6 cards or fewer — short sessions, often"

umask 077
mkdir -p "$PICKS_DIR"
[ -f "$DATA/cards.md" ] || cp "$SKILL_DIR/templates/cards.md" "$DATA/cards.md"
OTHER="$(other_of "$S")"
PICKS="$PICKS_DIR/$S.tsv"
SESSION="$PICKS_DIR/.session-$S.tsv"
SID="$(date '+%Y-%m-%d %H:%M')"

# Session file: header, then one card per line — id \t question \t option1 \t option2 …
{
  printf '#session\t%s\t%s\n' "$SID" "$LG"
  deck_tsv "$LG" | awk -F'\t' -v n="$N" -v other="$OTHER" -v seed="${COMPANION_SEED:-}" -v picksf="$PICKS" -v want="$WANT" '
    function sub_other(s,   i) { while ((i = index(s, "{{OTHER}}")) > 0) s = substr(s, 1, i-1) other substr(s, i+9); return s }
    function emit(i,   k, m, o, j, t) {
      m = split(opts[i], o, / \| /)
      for (k = m; k > 1; k--) { j = int(rand() * k) + 1; t = o[k]; o[k] = o[j]; o[j] = t }
      line = id[i] "\t" sub_other(q[i]); for (k = 1; k <= m; k++) line = line "\t" o[k]
      print line
    }
    BEGIN { if (seed != "") srand(seed); else srand()
            while ((getline l < picksf) > 0) { split(l, f, "\t"); if (f[1] != "ts") cnt[f[3]]++ }   # answers so far, per card
    }
    { c++; id[c] = $1; q[c] = $3; opts[c] = $4
      if ($1 == "feel-now") warm = c
      else score[c] = (($1 in cnt) ? cnt[$1] : 0) + rand() * 0.9 }
    END {
      if (warm) emit(warm)
      if (want != "") {                                       # explicitly requested cards, in order
        m = split(want, w, ",")
        for (p = 1; p <= m; p++) { hit = 0; for (i in score) if (id[i] == w[p]) { emit(i); delete score[i]; hit = 1 }
          if (!hit) print "picture-session: no card \"" w[p] "\" in the deck" > "/dev/stderr" }
        exit
      }
      for (p = 1; p <= n; p++) {                              # n least-answered cards
        best = 0
        for (i in score) if (!best || score[i] < score[best]) best = i
        if (!best) break
        emit(best); delete score[best]
      }
    }'
} > "$SESSION"

if [ "$HTML" = 0 ]; then
  awk -F'\t' -v name="$S" -v pt="$([ "$LG" = pt ] && echo 1)" '
    NR == 1 { next }
    NR == 2 {
      if (pt) {
        print "Sessão de figuras — " name
        print "Para o adulto: leia a pergunta uma vez, aponte cada figura, espere. Não reaja à escolha — não existe resposta certa."
        print "Se o primeiro cartão for 😢, pare e acolha. Se a pessoa perder o interesse, pare. \"Não\" também é resposta."
      } else {
        print "Picture session — " name
        print "For the grown-up: read the question once, point to each picture, then wait. Don'\''t react to the choice — there is no right answer."
        print "If card 1 is 😢, stop and comfort. If they lose interest, stop. \"No\" is an answer too."
      }
    }
    { printf "\n%d. [%s] %s\n   ", NR - 1, $1, $2
      for (i = 3; i <= NF; i++) { o = $i; sub(/^photo:[^ ]+/, "📷", o); printf "%s%s", (i > 3 ? "     " : ""), o }
      printf "\n" }
    END { print "\nRecord each pick: bin/record-pick.sh " name " <card> <picture or number> --how pointed --by <you>" }
  ' "$SESSION"
  exit 0
fi

OUT="$PICKS_DIR/session-$S.html"
{
cat <<'HTML'
<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Picture cards</title>
<style>
:root{--bg:#f6f1e7;--card:#fffdf8;--ink:#2f2a24;--soft:#8a8174;--line:#e4dccd;--pick:#7fa38a}
@media (prefers-color-scheme:dark){:root{--bg:#1f1d1a;--card:#2a2723;--ink:#f1ebe0;--soft:#a39a8c;--line:#3a3631;--pick:#7fa38a}}
*{box-sizing:border-box;margin:0}
html,body{height:100%;background:var(--bg);color:var(--ink);font:500 18px/1.3 system-ui,-apple-system,sans-serif;-webkit-user-select:none;user-select:none}
main{height:100vh;height:100dvh;display:flex;flex-direction:column;padding:16px;gap:16px}
#q{font-size:clamp(22px,5vw,40px);text-align:center;padding:8px 4px}
#opts{flex:1;min-height:0;display:grid;gap:14px;grid-template-columns:repeat(auto-fit,minmax(min(100%,220px),1fr));grid-auto-rows:minmax(0,1fr)}
.opt{background:var(--card);border:3px solid var(--line);border-radius:28px;padding:16px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;min-height:0;cursor:pointer;font:inherit;color:inherit;transition:border-color .2s}
.opt .e{font-size:min(20vmin,12vh,160px);line-height:1}
.opt img{max-width:100%;max-height:70%;border-radius:16px;object-fit:cover}
.opt .l{font-size:clamp(18px,4vw,28px)}
.opt.on{border-color:var(--pick)}
footer{display:flex;justify-content:space-between;color:var(--soft);font-size:14px}
footer button{background:none;border:1px solid var(--line);border-radius:999px;color:var(--soft);padding:6px 14px;font:inherit}
#end{display:none;flex:1;flex-direction:column;align-items:center;justify-content:center;gap:24px;text-align:center}
#end .big{font-size:clamp(48px,14vmin,120px)}
#grown{width:100%;max-width:560px;text-align:left;color:var(--soft);font-size:14px}
#grown textarea{width:100%;height:9em;margin-top:8px;background:var(--card);color:var(--ink);border:1px solid var(--line);border-radius:12px;padding:8px;font:13px ui-monospace,monospace;-webkit-user-select:text;user-select:text}
</style></head><body><main>
<div id="q"></div><div id="opts"></div>
<div id="end"><div class="big" id="bye"></div>
<div id="grown"><span id="gl"></span><textarea id="out" readonly></textarea></div></div>
<footer><span id="pos"></span><span><button id="skip"></button> <button id="stop"></button></span></footer>
</main><script>
HTML
awk -F'\t' -v name="$S" '
  function js(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/</, "\\u003c", s); return "\"" s "\"" }
  NR == 1 { printf "const LANG=%s, SESSION=%s, NAME=%s;\nconst CARDS=[\n", js($3), js($2), js(name); next }
  { printf "{id:%s,q:%s,o:[", js($1), js($2)
    for (i = 3; i <= NF; i++) printf "%s%s", (i > 3 ? "," : ""), js($i)
    print "]}," }
  END { print "];" }' "$SESSION"
cat <<'HTML'
const T = LANG==="pt"
  ? {skip:"pular",stop:"parar",bye:"Obrigado, "+NAME+" 💛",comfort:"🤗",gl:"Para o adulto — cole isto no chat do companion para registrar:"}
  : {skip:"skip",stop:"stop",bye:"Thank you, "+NAME+" 💛",comfort:"🤗",gl:"For the grown-up — paste this into the companion chat to record it:"};
const $ = id => document.getElementById(id);
$("skip").textContent=T.skip; $("stop").textContent=T.stop;
const picks=[]; let i=0, busy=false;
function label(o){const s=o.indexOf(" ");return s<0?"":o.slice(s+1)}
function key(o){const s=o.indexOf(" ");return s<0?o:o.slice(0,s)}
function show(){
  if(i>=CARDS.length) return finish();
  const c=CARDS[i]; $("q").textContent=c.q; $("pos").textContent=(i+1)+" / "+CARDS.length;
  const box=$("opts"); box.innerHTML="";
  c.o.forEach((o,n)=>{
    const b=document.createElement("button"); b.className="opt";
    const k=key(o);
    if(k.startsWith("photo:")){const im=document.createElement("img");im.src="../photos/"+k.slice(6);im.alt=label(o);b.appendChild(im)}
    else{const e=document.createElement("div");e.className="e";e.textContent=k;b.appendChild(e)}
    const l=document.createElement("div");l.className="l";l.textContent=label(o);b.appendChild(l);
    b.onclick=()=>choose(k,n+1,c,b); box.appendChild(b);
  });
}
function choose(k,pos,c,b){
  if(busy) return; busy=true; if(b) b.classList.add("on");
  picks.push("pick "+c.id+" "+k+" "+(pos||"-")+"/"+c.o.length);
  // warm-up gate: a sad start ends the session — comfort comes first
  const stopNow = c.id==="feel-now" && k==="😢";
  setTimeout(()=>{busy=false; i++; stopNow?finish(true):show()}, 450);
}
$("skip").onclick=()=>{ if(i<CARDS.length) choose("—",0,CARDS[i],null) };
$("stop").onclick=()=>finish();
function finish(sad){
  $("q").style.display=$("opts").style.display="none"; document.querySelector("footer").style.display="none";
  $("end").style.display="flex"; $("bye").textContent=sad?T.comfort:T.bye; $("gl").textContent=T.gl;
  $("out").value="session "+SESSION+"\n"+picks.join("\n");
  $("out").onclick=e=>e.target.select();
}
show();
</script></body></html>
HTML
} > "$OUT"
echo "$OUT"
