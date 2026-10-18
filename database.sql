-- Run in Supabase SQL Editor. Each set is a separate row.
create table public.workouts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 workout_date date not null,
 unit text not null default 'lb' check (unit in ('lb','kg')),
 notes text not null default '',
 created_at timestamptz not null default now()
);
create table public.sets (
 id uuid primary key default gen_random_uuid(),
 workout_id uuid not null references public.workouts(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 exercise_name text not null,
 set_number integer not null check (set_number > 0),
 weight numeric not null default 0 check (weight >= 0),
 reps integer not null default 0 check (reps >= 0),
 completed boolean not null default false,
 unique(workout_id,exercise_name,set_number)
);
create index workouts_user_date_idx on public.workouts(user_id,workout_date desc);
create index sets_workout_idx on public.sets(workout_id);
alter table public.workouts enable row level security;
alter table public.sets enable row level security;
create policy "Own workouts" on public.workouts for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "Own sets" on public.sets for all to authenticated using (user_id=auth.uid() and exists (select 1 from public.workouts w where w.id=workout_id and w.user_id=auth.uid())) with check (user_id=auth.uid() and exists (select 1 from public.workouts w where w.id=workout_id and w.user_id=auth.uid()));

-- Atomic saves: a failure rolls back both the workout and its sets.
create or replace function public.save_workout(
 p_id uuid, p_date date, p_unit text, p_notes text, p_sets jsonb
) returns uuid language plpgsql security invoker set search_path = public as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 if jsonb_typeof(p_sets) is distinct from 'array' or jsonb_array_length(p_sets) = 0 then
  raise exception 'At least one set is required';
 end if;
 if p_id is null then
  insert into public.workouts(user_id,workout_date,unit,notes)
  values(auth.uid(),p_date,p_unit,p_notes) returning id into v_id;
 else
  -- Serialize concurrent edits of the same workout.
  select id into v_id from public.workouts where id=p_id and user_id=auth.uid() for update;
  if v_id is null then raise exception 'Workout not found'; end if;
  update public.workouts set workout_date=p_date,unit=p_unit,notes=p_notes where id=v_id;
 end if;
 delete from public.sets where workout_id=v_id;
 insert into public.sets(workout_id,user_id,exercise_name,set_number,weight,reps,completed)
 select v_id,auth.uid(),s.exercise_name,s.set_number,s.weight,s.reps,s.completed
 from jsonb_to_recordset(p_sets) as s(exercise_name text,set_number integer,weight numeric,reps integer,completed boolean);
 return v_id;
end;
$$;
revoke all on function public.save_workout(uuid,date,text,text,jsonb) from public, anon;
grant execute on function public.save_workout(uuid,date,text,text,jsonb) to authenticated;
