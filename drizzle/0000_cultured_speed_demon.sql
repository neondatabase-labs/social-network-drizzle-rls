CREATE TABLE IF NOT EXISTS "chat_messages" (
	"id" text PRIMARY KEY NOT NULL,
	"message" text NOT NULL,
	"chat_id" text,
	"sender" text NOT NULL
);
--> statement-breakpoint
ALTER TABLE "chat_messages" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "chat_participants" (
	"chat_id" text,
	"user_id" text
);
--> statement-breakpoint
ALTER TABLE "chat_participants" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "chats" (
	"id" text PRIMARY KEY NOT NULL,
	"title" text NOT NULL,
	"owner_id" text,
	CONSTRAINT "chats_id_unique" UNIQUE("id")
);
--> statement-breakpoint
ALTER TABLE "chats" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "comments" (
	"id" text PRIMARY KEY NOT NULL,
	"post_id" text,
	"content" text,
	"userId" text
);
--> statement-breakpoint
ALTER TABLE "comments" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "posts" (
	"id" text PRIMARY KEY NOT NULL,
	"title" text NOT NULL,
	"content" text NOT NULL,
	"userId" text
);
--> statement-breakpoint
ALTER TABLE "posts" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "user_profiles" (
	"user_id" text,
	"name" text
);
--> statement-breakpoint
ALTER TABLE "user_profiles" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "users" (
	"user_id" text PRIMARY KEY NOT NULL,
	"email" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_chat_id_chats_id_fk" FOREIGN KEY ("chat_id") REFERENCES "public"."chats"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_sender_users_user_id_fk" FOREIGN KEY ("sender") REFERENCES "public"."users"("user_id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_participants" ADD CONSTRAINT "chat_participants_chat_id_chats_id_fk" FOREIGN KEY ("chat_id") REFERENCES "public"."chats"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_participants" ADD CONSTRAINT "chat_participants_user_id_users_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chats" ADD CONSTRAINT "chats_owner_id_users_user_id_fk" FOREIGN KEY ("owner_id") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "comments" ADD CONSTRAINT "comments_post_id_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "comments" ADD CONSTRAINT "comments_userId_users_user_id_fk" FOREIGN KEY ("userId") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "posts" ADD CONSTRAINT "posts_userId_users_user_id_fk" FOREIGN KEY ("userId") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_user_id_users_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("user_id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "chat_messages" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((select auth.user_id() in (select user_id from chat_participants where chat_id = "chat_messages"."chat_id")));--> statement-breakpoint
CREATE POLICY "chats-policy-insert" ON "chat_messages" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "chat_messages"."sender" and auth.user_id() in (select user_id from chat_participants where chat_id = "chat_messages"."chat_id")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "chat_participants" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((select auth.user_id() in (select user_id from chat_participants where chat_id = "chat_participants"."chat_id")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "chat_participants" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chat_id")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "chat_participants" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chat_id"))) WITH CHECK ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chat_id")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "chat_participants" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chat_id")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "chats" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((select auth.user_id() in (select user_id from chat_participants where chat_id = "chats"."id")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "chats" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "chats"."owner_id"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "chats" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "chats"."owner_id")) WITH CHECK ((select auth.user_id() = "chats"."owner_id"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "chats" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "chats"."owner_id"));--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-select" ON "comments" AS PERMISSIVE FOR SELECT TO "anonymous" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "comments" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "comments" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "comments"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "comments" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "comments"."userId")) WITH CHECK ((select auth.user_id() = "comments"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "comments" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "comments"."userId"));--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-select" ON "posts" AS PERMISSIVE FOR SELECT TO "anonymous" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "posts" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "posts" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "posts"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "posts" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "posts"."userId")) WITH CHECK ((select auth.user_id() = "posts"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "posts" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "posts"."userId"));--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-select" ON "user_profiles" AS PERMISSIVE FOR SELECT TO "anonymous" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "user_profiles" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "user_profiles" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "user_profiles"."user_id"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "user_profiles" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "user_profiles"."user_id")) WITH CHECK ((select auth.user_id() = "user_profiles"."user_id"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "user_profiles" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "user_profiles"."user_id"));