CREATE TABLE IF NOT EXISTS "chat_messages" (
	"id" text PRIMARY KEY NOT NULL,
	"message" text NOT NULL,
	"chatId" text,
	"sender" text NOT NULL
);
--> statement-breakpoint
ALTER TABLE "chat_messages" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "chat_participants" (
	"chatId" text,
	"userId" text,
	CONSTRAINT "chat_participants_chatId_userId_pk" PRIMARY KEY("chatId","userId")
);
--> statement-breakpoint
ALTER TABLE "chat_participants" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "chats" (
	"id" text PRIMARY KEY NOT NULL,
	"title" text NOT NULL,
	"ownerId" text
);
--> statement-breakpoint
ALTER TABLE "chats" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "comments" (
	"id" text PRIMARY KEY NOT NULL,
	"postId" text,
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
	"userId" text,
	"name" text,
	CONSTRAINT "user_profiles_userId_unique" UNIQUE("userId")
);
--> statement-breakpoint
ALTER TABLE "user_profiles" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "users" (
	"userId" text PRIMARY KEY NOT NULL,
	"email" text NOT NULL,
	"createdAt" timestamp DEFAULT now() NOT NULL,
	"updatedAt" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_chatId_chats_id_fk" FOREIGN KEY ("chatId") REFERENCES "public"."chats"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_sender_users_userId_fk" FOREIGN KEY ("sender") REFERENCES "public"."users"("userId") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_participants" ADD CONSTRAINT "chat_participants_chatId_chats_id_fk" FOREIGN KEY ("chatId") REFERENCES "public"."chats"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chat_participants" ADD CONSTRAINT "chat_participants_userId_users_userId_fk" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "chats" ADD CONSTRAINT "chats_ownerId_users_userId_fk" FOREIGN KEY ("ownerId") REFERENCES "public"."users"("userId") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "comments" ADD CONSTRAINT "comments_postId_posts_id_fk" FOREIGN KEY ("postId") REFERENCES "public"."posts"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "comments" ADD CONSTRAINT "comments_userId_users_userId_fk" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "posts" ADD CONSTRAINT "posts_userId_users_userId_fk" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_userId_users_userId_fk" FOREIGN KEY ("userId") REFERENCES "public"."users"("userId") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "chat_messages" AS PERMISSIVE FOR INSERT TO "authenticated";--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "chat_messages" AS PERMISSIVE FOR UPDATE TO "authenticated";--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "chat_messages" AS PERMISSIVE FOR DELETE TO "authenticated";--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "chat_messages" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((select auth.user_id()) in (select user_id from my_chats_participants where chat_id = "chat_messages"."chatId")));--> statement-breakpoint
CREATE POLICY "chats-policy-insert" ON "chat_messages" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (((select auth.user_id()) = "chat_messages"."sender" and (select auth.user_id()) in (select user_id from my_chats_participants where chat_id = "chat_messages"."chatId")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "chat_participants" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chatId")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "chat_participants" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chatId"))) WITH CHECK ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chatId")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "chat_participants" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = (select owner_id from chats where id = "chat_participants"."chatId")));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "chat_participants" AS PERMISSIVE FOR SELECT TO "authenticated" USING (false);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "chats" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "chats"."ownerId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "chats" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "chats"."ownerId")) WITH CHECK ((select auth.user_id() = "chats"."ownerId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "chats" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "chats"."ownerId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "chats" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((select auth.user_id()) = "chats"."ownerId" or (select auth.user_id()) in (select user_id from MY_CHATS_PARTICIPANTS where chat_id = "chats"."id")));--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-insert" ON "comments" AS PERMISSIVE FOR INSERT TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-update" ON "comments" AS PERMISSIVE FOR UPDATE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-delete" ON "comments" AS PERMISSIVE FOR DELETE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-select" ON "comments" AS PERMISSIVE FOR SELECT TO "anonymous" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "comments" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "comments"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "comments" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "comments"."userId")) WITH CHECK ((select auth.user_id() = "comments"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "comments" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "comments"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "comments" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-insert" ON "posts" AS PERMISSIVE FOR INSERT TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-update" ON "posts" AS PERMISSIVE FOR UPDATE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-delete" ON "posts" AS PERMISSIVE FOR DELETE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-select" ON "posts" AS PERMISSIVE FOR SELECT TO "anonymous" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "posts" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "posts"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "posts" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "posts"."userId")) WITH CHECK ((select auth.user_id() = "posts"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "posts" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "posts"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "posts" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-insert" ON "user_profiles" AS PERMISSIVE FOR INSERT TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-update" ON "user_profiles" AS PERMISSIVE FOR UPDATE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-delete" ON "user_profiles" AS PERMISSIVE FOR DELETE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-select" ON "user_profiles" AS PERMISSIVE FOR SELECT TO "anonymous" USING (true);--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "user_profiles" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((select auth.user_id() = "user_profiles"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "user_profiles" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((select auth.user_id() = "user_profiles"."userId")) WITH CHECK ((select auth.user_id() = "user_profiles"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "user_profiles" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((select auth.user_id() = "user_profiles"."userId"));--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-select" ON "user_profiles" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);--> statement-breakpoint
CREATE VIEW "public"."my_chats_participants" AS (select "chatId", "userId" from "chat_participants" where "chat_participants"."chatId" in (select "chatId" from "chat_participants" where "chat_participants"."userId" = auth.user_id()));