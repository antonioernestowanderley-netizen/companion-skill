# Companion — a two-way skill for two people who communicate differently

A small, local-first [OpenClaw](https://openclaw.ai) skill for **two specific people** who love each other and don't always understand each other: a parent and an autistic child, partners across neurotypes, siblings, an adult and an ageing parent.

**Each person writes about themselves, and about the other.** The companion keeps both voices, helps in hard moments, translates between them, prepares for transitions, and holds up a **mirror**: where how you see yourself and how you're seen line up, and where they don't. It learns the pair from real moments. It never invents advice.

> Communication breaks down *between* people, not inside one of them (the *double empathy problem*, Milton 2012). So both people get a voice. This is not a file kept on someone. It's a mirror two people hold together.

## What it is, and what it is NOT
- ✅ A shared memory of **how these two people reach each other**, built from both perspectives and from real moments.
- ✅ **Strengths first. Behaviour, never character.** Built for connection and dignity, never for "fixing" anyone.
- ✅ **Every suggestion cites its source** (`[self: Maya]`, `[ledger 2026-03-02]`, `[shared]`…). If it has no source, it doesn't say it.
- ❌ **Not a clinical authority.** It doesn't diagnose and doesn't give medical, behavioural or therapy advice. If something isn't recorded, it says so and points back to the people and their care team. **That refusal is the safety mechanism. Please keep it.**

## The architecture
| Layer | File | Who writes it | Authority |
|---|---|---|---|
| Self-portrait | `portraits/A-by-A.md` | A, in their own words (typed, dictated, chosen, drawn, AAC, with help) | **Inner experience:** what it's like, what they want |
| Witness portrait | `portraits/A-by-B.md` | B, about A | **Observable effects:** what it looks like from outside. One person's view |
| Ledger | `ledger.md` | either; both can add their side of the same moment | Track record |
| Shared understanding | `shared.md` | only what **both** agreed | Highest, for joint practice |
| Core + lenses | `common-core.md`, `lenses/autism.md` | the project | Defaults only; always overridden |

Four portraits per pair, all with the **same sections**, so they can be compared line by line.

## The modes
- **Moment:** help now. Two actions at most, each with its source.
- **Translate:** "how do I say this so it lands for them?" *Both* people can ask.
- **Picture portrait:** short picture-choice sessions so little ones and non-speakers write their own self-portrait (below).
- **Capture:** log a moment in seconds, by text, voice note or screenshot.
- **Prepare:** a trip, new school or appointment becomes a heads-up script in the other person's format.
- **Mirror:** the self-image vs. seen-image reconciliation, only when both are calm. It shows: common ground · seen from outside, not yet from inside · known inside, not yet seen · same thing, two readings. It never says who's right, never scores, and never shames masking.
- **Distil:** turns raw captures into tagged entries, and proposes portrait updates *to each portrait's author*, with evidence.
- **Passport:** a one-page, non-clinical card for teachers, sitters and grandparents.

## Picture portraits: a voice for little ones
A four-year-old, or someone who doesn't use words, still gets a self-portrait. A grown-up runs **short picture sessions** of 3–6 cards, as a script to read or a big-tile tap page for a phone or tablet. The child chooses; the companion records **only what was chosen**.
- **Their real world:** swap the default emoji for photos of *their* dog, blanket and favourite things.
- **Answers you can trust:** options are shuffled every session, and the position of each pick is recorded. If they pick by *place* rather than meaning, the summary says so.
- **A voice, not a guess:** a pick becomes a self-portrait line only when it's **steady** (3+ times, 2+ days, one clear choice). It's written in first person and cited: `Loud noise feels bad to me. [picks loud 4/5]`.
- **Their view wins on their inside.** When a steady pick disagrees with the adult's portrait, the pick stands, and the difference goes to the Mirror as "two readings".
- **Gentle by design:** a sad warm-up ends the session with comfort. No praise for "right" answers. Hand-guided picks don't count. "Skip" is an answer.

Cards ship in English and Brazilian Portuguese; add a language with `- es:` and `- options-es:` lines.

## Setup
1. Copy `skill/` into your OpenClaw skills dir, e.g. `~/.openclaw/workspace/skills/companion/`.
2. `bin/init.sh <you> <them>` creates `data/` (git-ignored, files readable by your user only).
3. Fill `data/pair.md`: who you both are, how each of you is identified, languages, care team, **emergency plan**.
4. Each person fills their **self-portrait first**, then the other's. Portraits start `visible-to: author-only`. Set `visible-to: both` when you're ready to share.
5. (Optional, macOS) local OCR for screenshots: `swiftc -O bin/ocr-vision.swift -o bin/ocr-vision`. Local voice notes: `pip install openai-whisper` (needs `ffmpeg`).
6. For a little one: `bin/picture-session.sh <name> --html --lang pt` and open the page it prints.
7. Tests: `bash tests/run.sh`.

**Upgrading from v1?** Run `init.sh` in the same folder. Your old `profile.md` becomes `portraits/<them>-by-<you>.md` and your ledger is carried over. The originals are left in place.

## Privacy and honesty (please read)
- **Each person owns what they write.** Portraits are private until their author shares them. The access gate and visibility rules are enforced by the skill's instructions, and `side-by-side.sh` filters by visibility in code too.
- **Where data goes, plainly:** voice notes and screenshots become text **on your machine**. But the agent's **language model reads your files**. If that model runs in the cloud (Claude, GPT, …), its provider receives them. If you need nothing to leave the device, run the agent on a local model.
- Keep clinical reports out of the repo. Share outward only through the **passport**.
- **Consent and dignity:** the person a portrait is about should, wherever possible, write their own portrait and approve what's shared. Many are perfectly capable of it. Children and people who need support still get a self-portrait: dictated, chosen from options, drawn, or written with help. The `voice:` field records how.

## Taking it further
Aggregating real use across families to find broader commonalities is powerful, and it touches **vulnerable people's data**. The bar is explicit consent, de-identification, and partnership with the autistic community and clinicians. That care isn't friction. It's what makes this trustworthy.

## License
MIT. See [LICENSE](LICENSE). Provided as-is, with no warranty and **no clinical claims of any kind.**
