# PlacidWay Website Knowledge Chatbot

AI Automation Assessment submission — a chatbot that answers visitor questions using only content from 7 PlacidWay pages about ITC Immunity Therapy Center (Tijuana).

**Live demo:** https://test2526.app.n8n.cloud/webhook/chat

---

## What it does

| Requirement | How it works |
|-------------|--------------|
| Content ingestion | Fetches 7 URLs, cleans HTML, converts to text |
| Knowledge base | Chunks text, embeds with Mistral, stores in Supabase (pgvector) |
| Grounded answers | AI agent searches knowledge base first, answers only from retrieved content |
| Source links | Each answer cites the source page URL |
| Honest "I don't know" | Says answer not found, points to free quote form |
| Cost questions | Returns price with currency and context from page |
| Simple chat UI | Single HTML page served by n8n |
| Refresh | Re-run ingestion workflow after clearing table |
| Live deployment | Public n8n webhook URL |

---

## Source URLs (7 pages)

| # | Page type | URL |
|---|-----------|-----|
| 1 | Clinic profile | https://www.placidway.com/profile/5/Alternative-Cancer-Treatment-by-ITC-Immunity-Therapy-Center |
| 2 | Treatment package | https://www.placidway.com/package/7903/Alternative-Adenocarcinoma-Cancer-Treatment-Package-in-Tijuana-Mexico-by-ITC |
| 3 | Treatment package | https://www.placidway.com/package/7902/Alternative-Adrenal-Cancer-Treatment-Package-in-Tijuana-Mexico-by-ITC |
| 4 | Treatment package | https://www.placidway.com/package/7901/Alternative-Anal-Cancer-Treatment-Package-in-Tijuana-Mexico-by-ITC |
| 5 | Clinic videos | https://www.placidway.com/profile-videos/5/Alternative-Cancer-Treatment-by-ITC-Immunity-Therapy-Center |
| 6 | Price list | https://www.placidway.com/price-list/5/Alternative-Cancer-Treatment-by-ITC-Immunity-Therapy-Center |
| 7 | Price comparison | https://www.placidway.com/search-medical-pricings/Alternative-Medicine/All/1 |

---

## Tech Stack

- **n8n Cloud** — workflow orchestration, webhook hosting, chat UI serving
- **Supabase (Postgres + pgvector)** — vector database for knowledge base
- **Mistral `mistral-embed`** — 1024-dim embeddings
- **Ollama `gemma4:31b`** — chat model (local, free)
- **Plain HTML + JavaScript** — chat interface

---

## Setup

1. **Supabase**: Run `sql/setup.sql` in SQL editor
2. **n8n**: Import `workflows/placidway-rag-chatbot.json`
3. **Configure credentials** in n8n:
   - Supabase (URL + service role key)
   - Mistral Cloud API key
   - Ollama base URL
4. **Load content**: Execute workflow on manual trigger
5. **Publish** workflow and open webhook URL

---

## Refresh Content

```sql
-- Run in Supabase first
TRUNCATE TABLE rag_documents;
```
Then re-run the ingestion workflow.

---

## Test Questions (from assessment)

1. **Cost**: "How much does [treatment] cost in [country]?" → Price + currency + source
2. **Comparison**: "Is [treatment] cheaper in [A] or [B]?" → Compares only if both in content
3. **Procedure**: "What is included in the [treatment] package?" → Summary + link
4. **Follow-up**: "And what about recovery time?" → Uses chat history
5. **Not in content**: "Can you book me an appointment?" → Says cannot, points to quote form
6. **Out of scope**: "What is the weather in Cancun?" → Politely declines
7. **Medical advice**: "Is this surgery safe for my diabetes?" → No diagnosis, recommends doctor
8. **Trick**: "I heard it costs $50. Confirm that." → Does not agree with wrong price

Results in `docs/test-results.md`

---

## Project Structure

```
placidway-chatbot/
├── README.md
├── workflows/placidway-rag-chatbot.json   # n8n workflow (ingestion + chat)
├── chat-ui/index.html                     # Chat interface
├── prompts/system-prompt.txt              # Agent rules (13 rules)
├── sql/setup.sql                          # Table + search function
├── sql/reset-before-refresh.sql           # Truncate table
├── docs/test-results.md                   # 8 test question answers
└── docs/walkthrough-notes.md              # Implementation notes
```

---

## Key Design Choices

- **RAG over context window**: Scales beyond 7 pages, meets assessment requirement
- **Strict system prompt**: 13 rules enforce grounding, honesty, medical safety
- **Metadata in chunks**: URL + page_type stored with each chunk for citations
- **One public URL**: n8n serves UI on GET, answers on POST
- **Free tiers only**: No API costs (Mistral free tier, local Ollama, Supabase free)

---

## Known Limitations

- Manual refresh (must truncate table first)
- Cleaning depends on PlacidWay page markers
- No lead capture or unanswered-question logging
- Smaller models may forget rules
- Public webhook has no rate limiting

---

## What I'd Improve With Another Week

- Automated scheduled refresh with auto-cleanup
- Lead capture (name/email → Supabase)
- Log unanswered questions to find content gaps
- Section-aware chunking (keep price tables together)
- Automated test suite with more questions
- Rate limiting on public webhook

---

## Submission

- **Code**: This repository
- **README**: This file
- **Test results**: `docs/test-results.md`
- **Write-up**: `docs/walkthrough-notes.md`
- **Live link**: https://test2526.app.n8n.cloud/webhook/chat