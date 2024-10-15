# Drizzle Postgres RLS Example

This repository contains a sample `schema.ts` for a social network application. In this example, we have a `users` table and a `posts` table. The `posts` table is similar to Twitter's posts, which are public. There's also a `chats` table, which is similar to Twitter's Direct Messages.

All of the authorization is modeled using Postgres RLS.

## Testing
1. Configure a `.env` file with your database credentials (see `.env.template`)
2. Run `bun install`
2. Run `bun run db:generate`
3. Run `bun run db:migrate`
