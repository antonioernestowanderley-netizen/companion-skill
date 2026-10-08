# Companion — a private skill for communicating with someone you love

A small, local-first [OpenClaw](https://openclaw.ai) skill that helps you communicate with **one specific person who communicates differently** — for example, an autistic family member. It's a **memory-and-pattern tool**, not an advice engine: it remembers what actually works for *that person* and reflects it back to you, calmly, when you're tired or stuck.

It was born from one family's real need. It is shared in the hope it helps others — **on the condition that it stays honest about what it is.**

## What it is — and is NOT
- ✅ A way to hold, in one place, **how to communicate with this specific person**: how they take in language, what overwhelms them, what soothes them, what lights them up — and to keep learning it from real moments.
- ✅ **Strengths-first.** Built around connection and dignity, never around "fixing" anyone.
- ❌ **Not a clinical authority.** It does not diagnose, does not give medical/behavioral/therapy advice, and never invents strategies. It surfaces only what *you* and *their care team* have recorded, and otherwise points back to the professionals. **That refusal is the safety mechanism.** Please keep it.

> "If you've met one autistic person, you've met *one* autistic person." The shared base is **posture, never prescription** — and a person's own profile always overrides it.

## How it's built — three layers
1. **`common-core.md`** — the shared base: evidence-informed *communication-posture* defaults (presume competence, behavior is communication, regulate before problem-solving, literal language, predictability, sensory-first, interests as the bridge, never shame…). Reusable across people. Never holds anyone's private specifics.
2. **`profile.md`** — *this* person. You write it. **It overrides the Core** wherever they differ.
3. **`interaction-ledger.md`** — append-only log of real moments. This is what makes it *theirs* over time, not generic.

The model reads them in order: Core → profile → ledger.

## Setup
1. Copy the `skill/` folder into your OpenClaw workspace skills dir (e.g. `~/.openclaw/workspace/skills/companion/`). It auto-discovers — no restart.
2. `cp profile.template.md profile.md` and fill it with your person. `cp interaction-ledger.template.md interaction-ledger.md`.
3. (Optional, macOS) build the local OCR helper so you can log from screenshots:
   `swiftc -O bin/ocr-vision.swift -o bin/ocr-vision`
4. Talk to your agent about a moment, or send it a voice note / screenshot (in your private chat). It captures, learns, and helps.

## Privacy (please read)
- **Your person's data is theirs.** `profile.md` and `interaction-ledger.md` are **git-ignored** by default so you don't accidentally publish them. Keep clinical reports off the repo entirely.
- Voice/screenshot understanding runs **locally** (whisper + macOS Vision OCR) — nothing is sent to a cloud service by this skill.
- If you ever share access (a care circle), share a **non-clinical "passport"** level — not the clinical profile.
- **Consent & dignity:** the person this is about should, wherever possible, have a say in what's recorded and shared about them. Many of them are perfectly capable of it. Involve them.

## If you want to take this further
Aggregating real usage across families to find broader commonalities is powerful — and touches **vulnerable people's data**. Don't do it casually: explicit consent, de-identification, and partnership with the autistic community and clinicians are the bar. That care isn't friction — it's what makes it trustworthy.

## License
MIT — see [LICENSE](LICENSE). Provided as-is, with no warranty, and **no clinical claims of any kind.**
