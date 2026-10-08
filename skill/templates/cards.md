# Picture cards — the self-portrait for little ones and people who answer best by choosing

> `bin/picture-session.sh` copies this deck to `data/cards.md` the first time it runs. **Edit that copy, not this one.** Swap the defaults for *their* real things: their dog, their blanket, their game. The more a card looks like their life, the more the answer means. A photo works better than an emoji for small children: put it in `data/photos/` and write the option as `photo:bunny.jpg Bunny`.
>
> **Format.** `### card-id`, then `- section:` (a portrait heading), one question line per language (`- en:`, `- pt:`, add `- es:` etc.), then options. Use `- options: faces` for the feelings scale, or `- options-<lang>: 🅰 label | 🅱 label`. **2–3 options; never more than 4.** The first token of each option (emoji or `photo:file`) is its key and must be the same in every language. `{{OTHER}}` becomes the other person's name.
>
> **How much a pick tells you.** Yes/no cards are the weakest evidence; small children lean towards "yes". Faces and concrete pictures are stronger. One pick is a hint. The same pick on different days is a voice.

- faces-en: 😀 good | 😐 okay | 😣 bad
- faces-pt: 😀 bom | 😐 mais ou menos | 😣 ruim

### feel-now
- section: (warm-up)
- en: How do you feel right now?
- pt: Como você está agora?
- options-en: 😀 happy | 😐 okay | 😢 sad
- options-pt: 😀 feliz | 😐 mais ou menos | 😢 triste

### love-most
- section: Who they are
- en: What do you love most?
- pt: Do que você mais gosta?
- options-en: 🚂 trains | 🐶 animals | 🎨 drawing
- options-pt: 🚂 trens | 🐶 bichos | 🎨 desenhar

### tell-or-show
- section: How they communicate
- en: When someone explains something, what's best?
- pt: Quando alguém te explica uma coisa, o que é melhor?
- options-en: 🗣️ tell me | 👉 show me
- options-pt: 🗣️ me fala | 👉 me mostra

### fast-slow
- section: How they communicate
- en: When people talk to you — fast or slow?
- pt: Quando falam com você — rápido ou devagar?
- options-en: 🐇 fast | 🐢 slow
- options-pt: 🐇 rápido | 🐢 devagar

### wait
- section: How they communicate
- en: When someone asks you something, should they wait for you?
- pt: Quando alguém te pergunta uma coisa, deve esperar você?
- options-en: 👍 yes, wait | 🙅 no
- options-pt: 👍 sim, espera | 🙅 não

### loud
- section: What overloads them
- en: Loud noise. How does it feel?
- pt: Barulho alto. Como é pra você?
- options: faces

### crowd
- section: What overloads them
- en: Lots of people around you.
- pt: Muita gente em volta.
- options: faces

### bright
- section: What overloads them
- en: Very bright light.
- pt: Luz muito forte.
- options: faces

### surprise
- section: What overloads them
- en: The plan changes. Surprise!
- pt: O plano mudou. Surpresa!
- options: faces

### upset-help
- section: What helps
- en: When things feel hard, what helps?
- pt: Quando tudo fica difícil, o que te ajuda?
- options-en: 🤗 a hug | 🛋️ a quiet place | 🧸 my special thing
- options-pt: 🤗 abraço | 🛋️ um cantinho quieto | 🧸 meu brinquedo especial

### upset-talk
- section: What helps
- en: When things feel hard, should people…
- pt: Quando tudo fica difícil, as pessoas devem…
- options-en: 🤫 be quiet | 💬 talk to me
- options-pt: 🤫 ficar quietinhas | 💬 falar comigo

### hugs
- section: What helps
- en: A big tight hug.
- pt: Abraço bem apertado.
- options: faces

### music
- section: What helps
- en: Music when things feel hard?
- pt: Música quando tudo fica difícil?
- options-en: 🎵 yes | 🔇 no
- options-pt: 🎵 sim | 🔇 não

### play-with
- section: Connection
- en: What do you like doing with {{OTHER}}?
- pt: O que você gosta de fazer com {{OTHER}}?
- options-en: 📚 reading | 🏃 running around | 🎨 making things
- options-pt: 📚 ler | 🏃 correr | 🎨 fazer coisas

### laugh
- section: Connection
- en: What makes you laugh?
- pt: O que te faz rir?
- options-en: 🤪 silly faces | 🤸 tickles and jumping | 🎶 funny songs
- options-pt: 🤪 caretas | 🤸 cócegas e pulos | 🎶 músicas engraçadas

### know-next
- section: Predictability
- en: Do you like knowing what comes next?
- pt: Você gosta de saber o que vem depois?
- options-en: 👍 yes | 👎 no
- options-pt: 👍 sim | 👎 não

### stop-play
- section: Predictability
- en: Time to stop playing.
- pt: Hora de parar de brincar.
- options: faces

### big-voice
- section: What lands, what backfires
- en: A grown-up talks to you very loud.
- pt: Um adulto fala muito alto com você.
- options: faces

### soft-voice
- section: What lands, what backfires
- en: A grown-up talks to you softly and slowly.
- pt: Um adulto fala baixinho e devagar com você.
- options: faces

### good-at
- section: Strengths
- en: What are you great at?
- pt: Em que você é craque?
- options-en: 🏗️ building | 🏃 running | 💛 being kind
- options-pt: 🏗️ montar coisas | 🏃 correr | 💛 dar carinho

### wish
- section: In their own words
- en: I want {{OTHER}} to…
- pt: Eu quero que {{OTHER}}…
- options-en: 🧩 play with me more | 👂 listen to me | 🐢 go slower
- options-pt: 🧩 brinque mais comigo | 👂 me escute | 🐢 vá mais devagar
