import { sql } from "drizzle-orm";
import {
  integer,
  pgTable,
  serial,
  text,
  uuid,
  timestamp,
  pgPolicy,
} from "drizzle-orm/pg-core";
import { authenticatedRole, anonymousRole, authUid } from "drizzle-orm/neon";

// Temporary: this should be imported from "drizzle-orm/neon"
import { crudPolicy } from "./";

// core `users` table, this remains private
// enabling RLS without policies locks this down to admin-only, users cannot edit
export const users = pgTable("users", {
  userId: serial("user_id").primaryKey(),
  email: text("email").unique().notNull(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

// `user_profile` table has public read / private modify
// anyone can see a user profile but only the user associated can edit their profile
export const userProfiles = pgTable(
  "user_profiles",
  {
    userId: serial("user_id").references(() => users.userId),
    name: text("name"),
  },
  (t) =>
    // this table is pretty straightforward CRUD and therefore
    // can use the simplified `crudPolicy` function
    [
      // anyone (anonymous) can read
      crudPolicy({
        // `anonymousRole` is a default role
        role: anonymousRole,
        read: true,
      }),
      // only authenticated -> users can modify
      crudPolicy({
        // `authenticatedRole` is a default role
        role: authenticatedRole,
        read: true,
        modify: authUid(t.userId),
      }),
    ],
);

// the messages within a "chat"
export const chatMessages = pgTable(
  "chat_messages",
  {
    id: serial("id").primaryKey(),
    message: text("message").notNull(),
    chatId: serial("chat_id").references(() => chats.id),
    sender: uuid("sender")
      .references(() => users.userId, { onDelete: "cascade" })
      .notNull(),
  },
  (t) => [
    // We need `pgPolicy` here as the rules are more complex
    // Users cannot update or delete chat messages, not even their own
    // Creating a policy for "insert" allows creation and ignoring
    // update/delete defaults to not allowing
    pgPolicy("chats-policy-insert", {
      for: "insert",
      to: authenticatedRole,
      withCheck: sql`select auth.user_id() = ${t.sender} and auth.user_id() in (select user_id from chat_participants where chat_id = ${t.chatId})`,
    }),

    // A simpler CRUD read rule for any participant to be able to read
    // any message within the chat
    crudPolicy({
      role: authenticatedRole,
      read: sql`select auth.user_id() in (select user_id from chat_participants where chat_id = ${t.chatId})`,
    }),
  ],
);

// the users participating in a chat, connecting users and chats tables
export const chatParticipants = pgTable(
  "chat_participants",
  {
    chatId: serial("chat_id").references(() => chats.id),
    userId: serial("user_id").references(() => users.userId),
  },
  (t) => [
    // Users in the chat can see (read) the participant list
    crudPolicy({
      role: authenticatedRole,
      read: sql`select auth.user_id() in (select user_id from chat_participants where chat_id = ${t.chatId})`,
    }),
  ],
);

export const chats = pgTable(
  "chats",
  {
    id: serial("id").primaryKey(),
    title: text("title").notNull(),
  },
  (t) => [
    // Chat participants can see the chats they are in
    crudPolicy({
      role: authenticatedRole,
      read: sql`select auth.user_id() in (select user_id from chat_participants where chat_id = ${t.id})`,
    }),
  ],
);

// `posts` like a simple blog post
export const posts = pgTable(
  "posts",
  {
    id: serial("id").primaryKey(),
    title: text("title").notNull(),
    content: text("content").notNull(),
    userId: serial("userId").references(() => users.userId),
  },
  (t) =>
    // Simple CRUD rules apply here
    [
      // Anyone can read these posts
      crudPolicy({
        role: anonymousRole,
        read: true,
      }),
      // Authenticated users can read / write their own posts
      crudPolicy({
        role: authenticatedRole,
        read: true,
        // checking that the post table `userId` -> `t.userId` is
        // the authenticated user and has access to modify the post
        modify: authUid(t.userId),
      }),
    ],
);

// `comments` like simple post comments
export const comments = pgTable(
  "comments",
  {
    id: serial("id").primaryKey(),
    postId: integer("post_id").references(() => posts.id),
    content: text("content"),
    userId: uuid("userId").references(() => users.userId),
  },
  (t) =>
    // Same CRUD rules as `posts`
    // anyone can read comments
    // authenticated users can create/update/delete their own comments
    [
      crudPolicy({
        role: anonymousRole,
        read: true,
      }),
      crudPolicy({
        role: authenticatedRole,
        read: true,
        modify: authUid(t.userId),
      }),
    ],
);
