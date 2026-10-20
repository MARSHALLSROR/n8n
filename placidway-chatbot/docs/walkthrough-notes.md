# Walkthrough notes (for the review call)

Simple notes so I can explain the project in my own words.

## 30-second version

I built a chatbot in n8n that answers questions strictly using content from the 7 PlacidWay pages for ITC Immunity Therapy Center. I download the pages, clean their structure, split them into chunks, store them in Supabase along with their metadata/URLs, and when someone asks a question, an AI Agent uses vector search to retrieve relevant chunks and generate grounded answers. If information is missing, it explicitly states so and directs users to request a free quote.

---

## Part 1: How the content gets in (Ingestion Pipeline)

1. **URL List:** A list of the 7 PlacidWay URLs is defined in a Set node, and Split Out creates one item per page.
2. **Scraping:** An HTTP Request node downloads each page HTML.
3. **Extraction & Conversion:** The HTML node extracts the title and main content block (`main` tag). The Markdown node converts it to clean text.
4. **Targeted Cleaning:** The `md details` node strips navigation menus, footers, booking widgets, and ads for other clinics. We specifically refined the string-splitting logic so bottom-page sections like **Package Inclusions** and **Pricing Tiers** are never accidentally cut off.
5. **Chunking:** Text is split into chunks of **800 characters** with **100-character overlap**. Each chunk retains metadata (`url` and `page_type`).
6. **Vector Store & Batching Safeguard:** Mistral generates vector embeddings for each chunk, which are stored in Supabase (`vector` column). To avoid API payload limits and silent failures, vector insertion uses a conservative batch size (16–32 items/batch).

---

## Part 2: How a question is answered (Retrieval & Agent Pipeline)

1. **Webhook Interface:** The chat frontend sends user messages to the n8n webhook along with a unique `chatInput` and `sessionId`.
2. **Conversational Memory:** The AI Agent utilizes session-based memory, allowing seamless follow-up questions (e.g., asking "What is included?" followed by "And what about the price?").
3. **Vector Tool Retrieval:** The agent uses one main search tool: querying Supabase chunks using cosine similarity. We set `topK = 8` (increased from 5) so the model retrieves enough context across different pages to accurately handle comparative questions (e.g., comparing Lung Cancer vs. Prostate Cancer prices).
4. **Strict System Prompt Rules:** The system prompt enforces strict rules:
   - Must search before answering.
   - Must look up both entities in comparison questions before declaring pricing missing.
   - If both treatments share the same baseline price ($18,995), state that they cost the same.
   - Refuse medical advice/safety claims and redirect users to consult a doctor.
   - Politely decline out-of-scope questions (e.g., weather).
   - Append source URLs directly from retrieved metadata.
5. **Response Delivery:** The response is returned as JSON and rendered in the web chat interface with direct link chips.

---

## Why RAG for only 7 pages?

While 7 pages could theoretically fit inside a single context window, using a RAG architecture satisfies the assignment brief, demonstrates scalable vector search engineering, and ensures the system can easily scale to hundreds of clinic pages without re-engineering the pipeline.

---

## Why I made these choices

- **n8n:** Provides a clear visual workflow, integrated webhook endpoints, and hosting in a single framework.
- **Supabase:** Free, robust PostgreSQL database with `pgvector` support, enabling fast semantic search and metadata filtering for URL sources.
- **Single Host Endpoint:** n8n serves the custom chat UI on `GET` and handles logic on `POST`, making testing straightforward for reviewers.
- **Strict Prompt Engineering:** Focused heavily on preventing hallucinations, enforcing medical disclaimers, and handling edge/trick cases (e.g., verifying a fake $50 price claim).

---

## Things I know are not perfect & future improvements

- **Manual Re-indexing:** Re-running the pipeline currently requires clearing the Supabase table first to avoid duplicate vectors.
- **Lead Capture Integration:** While it points users to the quote link (`/request-info`), a full CRM lead capture node (collecting name/email directly in chat) could be added.
- **Unanswered Query Logging:** Could add a Supabase table or Slack/Email alert when the bot cannot find an answer, helping identify knowledge gaps.
- **Structural Scraping Dependencies:** Cleaning regex relies on PlacidWay's current HTML structure; a headless browser or specialized parser would be better for dynamic UI updates.

---

## Small live changes I can demonstrate on a call

1. **Adjusting Retrieval Limits:** Changing `topK` in the Supabase retrieval tool node to show how context volume impacts comparison accuracy.
2. **System Prompt Tweaks:** Demonstrating live prompt updates (e.g., adjusting medical disclaimer phrasing or multilingual tone).
3. **Adding New Pages:** Adding an 8th URL to the ingestion node and re-indexing the database live.