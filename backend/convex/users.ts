import { v } from "convex/values";
import { internalMutation, internalQuery } from "./_generated/server";

// user related internal functions, only called from http routes

export const findByEmail = internalQuery({
  args: { email: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("users")
      .withIndex("by_email", (q) => q.eq("email", args.email))
      .unique();
  },
});

export const findByToken = internalQuery({
  args: { token: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("users")
      .withIndex("by_token", (q) => q.eq("token", args.token))
      .unique();
  },
});

export const create = internalMutation({
  args: {
    name: v.string(),
    email: v.string(),
    passwordHash: v.string(),
    token: v.string(),
  },
  handler: async (ctx, args) => {
    const id = await ctx.db.insert("users", {
      name: args.name,
      email: args.email,
      passwordHash: args.passwordHash,
      token: args.token,
      createdAt: Date.now(),
    });
    return id;
  },
});

export const setToken = internalMutation({
  args: { userId: v.id("users"), token: v.string() },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, { token: args.token });
  },
});

export const clearToken = internalMutation({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, { token: undefined });
  },
});
