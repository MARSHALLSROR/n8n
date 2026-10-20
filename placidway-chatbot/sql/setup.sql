-- Run once in the Supabase SQL editor.
-- Embedding size 1024 matches Mistral "mistral-embed".
-- If you change the embedding model, change 1024 in the three places below.

create extension if not exists vector;

create table if not exists rag_documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(1024)
);

create or replace function match_documents (
  query_embedding vector(1024),
  match_count int default null,
  filter jsonb default '{}'
) returns table (id bigint, content text, metadata jsonb, similarity float)
language plpgsql as $$
begin
  return query
  select d.id, d.content, d.metadata, 1 - (d.embedding <=> query_embedding) as similarity
  from rag_documents d
  where d.metadata @> filter
  order by d.embedding <=> query_embedding
  limit match_count;
end;
$$;
