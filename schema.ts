import { sql } from "drizzle-orm";
import {
  pgTable,
  text,
  timestamp,
  pgPolicy,
  pgView,
  primaryKey,
} from "drizzle-orm/pg-core";
import {
  authenticatedRole,
  anonymousRole,
  crudPolicy,
  authUid,
} from "drizzle-orm/neon";
import { eq, inArray } from "drizzle-orm";

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
    userId: text("user_id")
      .references(() => users.userId)
      .unique(),
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
      read: sql`((select auth.user_id()) in (select user_id from my_chats_participants where chat_id = ${table.chatId}))`,
      modify: null,
    }),

    // complex table access require `pgPolicy` functions
    // authenticated users can only insert – because there is no delete or update policy, users cannot update or delete their own or others' messages
    pgPolicy("chats-policy-insert", {
      for: "insert",
      to: authenticatedRole,
      withCheck: sql`((select auth.user_id()) = ${table.sender} and (select auth.user_id()) in (select user_id from my_chats_participants where chat_id = ${table.chatId}))`,
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
    primaryKey({ columns: [table.chatId, table.userId] }),
    // authenticated users can read chat participant list
    crudPolicy({
      role: authenticatedRole,

      // Since we can't create a RLS policy for this rule
      // it's better to block its reading, and only rely on the view `my_chats_participants`
      read: false,
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

      // The `(select auth.user_id()) = ${table.ownerId} OR` clause is needed because RLS rules are evaluated
      // based on existing RLS restrictions. Without this clause, we couldn’t insert the first chatParticipant
      // in a chat, as the initial rule only allowed access to chats where the user is already a participant.
      read: sql`((select auth.user_id()) = ${table.ownerId} or (select auth.user_id()) in (select user_id from MY_CHATS_PARTICIPANTS where chat_id = ${table.id}))`,
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

// This view is necessary because RLS
// does not support rules that filter a table based on its own data in a recursive way.
// Specifically, RLS cannot handle conditions like:
// "Show only the chat participants of chats where I am also a participant."
// Attempting to enforce this rule directly on the `chatParticipants` table
// leads to a recursion error. Using a view allows us to apply this filtering logic
// without running into RLS limitations.
export const myChatParticipantsView = pgView("my_chats_participants").as(
  (qb) => {
    const subquery = qb
      .select({ chatId: chatParticipants.chatId })
      .from(chatParticipants)
      .where(eq(chatParticipants.userId, sql`auth.user_id()`));

    return qb
      .select()
      .from(chatParticipants)
      .where(inArray(chatParticipants.chatId, subquery));
  },
);
