create table if not exists public.password_reset_codes (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  code text not null check (code ~ '^[0-9]{6}$'),
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists password_reset_codes_email_created_at_idx
  on public.password_reset_codes (email, created_at desc);

create index if not exists password_reset_codes_lookup_idx
  on public.password_reset_codes (email, code, used, expires_at);

alter table public.password_reset_codes enable row level security;

revoke all on table public.password_reset_codes from anon, authenticated;
