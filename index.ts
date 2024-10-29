// TODO: This file is temporary until Drizzle ORM RLS is finished.

import {
  entityKind,
  SQL,
  sql,
  type DrizzleEntityClass,
} from "drizzle-orm";
import {
  pgPolicy,
  PgRole,
  type AnyPgColumn,
  type PgPolicyToOption,
} from "drizzle-orm/pg-core";

export function is<T extends DrizzleEntityClass<any>>(
  value: any,
  type: T,
): value is InstanceType<T> {
  if (!value || typeof value !== "object") {
    return false;
  }

  if (value instanceof type) {
    // eslint-disable-line no-instanceof/no-instanceof
    return true;
  }

  if (!Object.prototype.hasOwnProperty.call(type, entityKind)) {
    throw new Error(
      `Class "${
        type.name ?? "<unknown>"
      }" doesn't look like a Drizzle entity. If this is incorrect and the class is provided by Drizzle, please report this as a bug.`,
    );
  }

  let cls = value.constructor;
  if (cls) {
    // Traverse the prototype chain to find the entityKind
    while (cls) {
      if (entityKind in cls && cls[entityKind] === type[entityKind]) {
        return true;
      }

      cls = Object.getPrototypeOf(cls);
    }
  }

  return false;
}

export const crudPolicy = (options: {
  role: PgPolicyToOption;
  read: SQL | boolean | null;
  modify: SQL | boolean | null;
}) => {
  if (options.read === undefined) {
    throw new Error("crudPolicy requires a read policy");
  }

  if (options.modify === undefined) {
    throw new Error("crudPolicy requires a modify policy");
  }
  
  let read: SQL | undefined;
  if (options.read === true) {
    read = sql`true`;
  } else if (options.read === false) {
    read = sql`false`;
  } else if (options.read !== null) {
    read = options.read;
  }

  let modify: SQL | undefined;
  if (options.modify === true) {
    modify = sql`true`;
  } else if (options.modify === false) {
    modify = sql`false`;
  } else if (options.modify !== null) {
    modify = options.modify;
  }

  let rolesName = "";
  if (Array.isArray(options.role)) {
    rolesName = options.role
      .map((it) => {
        return is(it, PgRole) ? it.name : (it as string);
      })
      .join("-");
  } else {
    rolesName = is(options.role, PgRole)
      ? options.role.name
      : (options.role as string);
  }

  return [
    read && pgPolicy(`crud-${rolesName}-policy-select`, {
      for: "select",
      to: options.role,
      using: read,
    }),

    modify && pgPolicy(`crud-${rolesName}-policy-insert`, {
      for: "insert",
      to: options.role,
      withCheck: modify,
    }),
    modify && pgPolicy(`crud-${rolesName}-policy-update`, {
      for: "update",
      to: options.role,
      using: modify,
      withCheck: modify,
    }),
    modify && pgPolicy(`crud-${rolesName}-policy-delete`, {
      for: "delete",
      to: options.role,
      using: modify,
    }),
  ].filter(Boolean);
};

export const authUid = (userIdColumn: AnyPgColumn) => sql`(select auth.user_id() = ${userIdColumn})`;