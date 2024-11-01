import { sql } from "drizzle-orm";
import { pgTable, text, timestamp, pgPolicy } from "drizzle-orm/pg-core";
import { authenticatedRole, anonymousRole } from "drizzle-orm/neon";

// TODO: this should be imported from "drizzle-orm/neon"
import { crudPolicy, authUid } from "./";

// all tables are admin-only by default
// RLS is used to allow certain things to be created, read, updated, or deleted

// private table, without RLS policies this is admin-only
export const users = pgTable("users", {
  userId: text("user_id").primaryKey(),
  email: text("email").unique().notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
}).enableRLS();

// public read / authenticated user modify
export const userProfiles = pgTable(
  "user_profiles",
  {
    userId: text("user_id").references(() => users.userId),
    name: text("name"),
  },
  (table) =>
    // simple CRUD tables use the `crudPolicy` function
    [
      // anyone (anonymous) can read
      crudPolicy({
        role: anonymousRole, // default role
        read: true,
        modify: null,
      }),
      // authenticated users can only modify their data
      crudPolicy({
        role: authenticatedRole, // default role
        read: true,
        modify: authUid(table.userId),
      }),
    ],
);

export const chatMessages = pgTable(
  "chat_messages",
  {
    id: text("id").primaryKey(),
    message: text("message").notNull(),
    chatId: text("chat_id").references(() => chats.id),
    sender: text("sender")
      .references(() => users.userId, { onDelete: "cascade" })
      .notNull(),
  },
  (table) => [
    // authenticated users can read messages for chats they participate in
    crudPolicy({
      role: authenticatedRole,
      read: sql`(select auth.user_id() in (select user_id from chat_participants where chat_id = ${table.chatId}))`,
      modify: null,
    }),

    // complex table access require `pgPolicy` functions
    // authenticated users can only insert – because there is no delete or update policy, users cannot update or delete their own or others' messages
    pgPolicy("chats-policy-insert", {
      for: "insert",
      to: authenticatedRole,
      withCheck: sql`(select auth.user_id() = ${table.sender} and auth.user_id() in (select user_id from chat_participants where chat_id = ${table.chatId}))`,
    }),
  ],
);

// chat participants, connecting users and chats tables
export const chatParticipants = pgTable(
  "chat_participants",
  {
    chatId: text("chat_id").references(() => chats.id),
    userId: text("user_id").references(() => users.userId),
  },
  (table) => [
    // authenticated users can read chat participant list
    crudPolicy({
      role: authenticatedRole,
      read: sql`(select auth.user_id() in (select user_id from chat_participants where chat_id = ${table.chatId}))`,
      modify: sql`(select auth.user_id() = (select owner_id from chats where id = ${table.chatId}))`,
    }),
  ],
);

export const chats = pgTable(
  "chats",
  {
    id: text("id").primaryKey(),
    title: text("title").notNull(),
    ownerId: text("owner_id").references(() => users.userId),
  },
  (table) => [
    // authenticated users can read list of chats they are participating in. Anyone can create a chat and become the owner
    // of that chat.
    crudPolicy({
      role: authenticatedRole,
      read: sql`(select auth.user_id() in (select user_id from chat_participants where chat_id = ${table.id}))`,
      modify: authUid(table.ownerId),
    }),
  ],
);

export const posts = pgTable(
  "posts",
  {
    id: text("id").primaryKey(),
    title: text("title").notNull(),
    content: text("content").notNull(),
    userId: text("userId").references(() => users.userId),
  },
  (table) => [
    // anyone (anonymous) can read
    crudPolicy({
      role: anonymousRole,
      read: true,
      modify: null,
    }),
    // authenticated users can can read and modify their own posts
    crudPolicy({
      role: authenticatedRole,
      read: true,
      // `userId` column matches `auth.user_id()` allows modify
      modify: authUid(table.userId),
    }),
  ],
);

export const comments = pgTable(
  "comments",
  {
    id: text("id").primaryKey(),
    postId: text("post_id").references(() => posts.id),
    content: text("content"),
    userId: text("userId").references(() => users.userId),
  },
  (table) => [
    // anyone (anonymous) can read
    crudPolicy({
      role: anonymousRole,
      read: true,
      modify: null,
    }),
    // authenticated users can can read and modify their own comments
    crudPolicy({
      role: authenticatedRole,
      read: true,
      modify: authUid(table.userId),
    }),
  ],
);
