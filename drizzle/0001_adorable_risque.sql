ALTER TABLE "user_profiles" ADD CONSTRAINT "user_profiles_user_id_unique" UNIQUE("user_id");--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-insert" ON "chat_messages" AS PERMISSIVE FOR INSERT TO "authenticated";--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-update" ON "chat_messages" AS PERMISSIVE FOR UPDATE TO "authenticated";--> statement-breakpoint
CREATE POLICY "crud-authenticated-policy-delete" ON "chat_messages" AS PERMISSIVE FOR DELETE TO "authenticated";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-insert" ON "comments" AS PERMISSIVE FOR INSERT TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-update" ON "comments" AS PERMISSIVE FOR UPDATE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-delete" ON "comments" AS PERMISSIVE FOR DELETE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-insert" ON "posts" AS PERMISSIVE FOR INSERT TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-update" ON "posts" AS PERMISSIVE FOR UPDATE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-delete" ON "posts" AS PERMISSIVE FOR DELETE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-insert" ON "user_profiles" AS PERMISSIVE FOR INSERT TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-update" ON "user_profiles" AS PERMISSIVE FOR UPDATE TO "anonymous";--> statement-breakpoint
CREATE POLICY "crud-anonymous-policy-delete" ON "user_profiles" AS PERMISSIVE FOR DELETE TO "anonymous";