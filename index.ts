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
  read?: SQL | boolean;
  modify?: SQL | boolean;
}) => {
  const read: SQL =
    options.read === true
      ? sql`true`
      : options.read === false || options.read === undefined
        ? sql`false`
        : options.read;

  const modify: SQL =
    options.modify === true
      ? sql`true`
      : options.modify === false || options.modify === undefined
        ? sql`false`
        : options.modify;

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
    pgPolicy(`crud-${rolesName}-policy-insert`, {
      for: "insert",
      to: options.role,
      withCheck: modify,
    }),
    pgPolicy(`crud-${rolesName}-policy-update`, {
      for: "update",
      to: options.role,
      using: modify,
      withCheck: modify,
    }),
    pgPolicy(`crud-${rolesName}-policy-delete`, {
      for: "delete",
      to: options.role,
      using: modify,
    }),
    pgPolicy(`crud-${rolesName}-policy-select`, {
      for: "select",
      to: options.role,
      using: read,
    }),
  ];
};
