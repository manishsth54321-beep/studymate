import { v } from "convex/values";
import { internalMutation, internalQuery } from "./_generated/server";

// subjects table operations

export const list = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("subjects")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("desc")
      .collect();
  },
});

export const add = internalMutation({
  args: {
    userId: v.id("users"),
    name: v.string(),
    code: v.string(),
    description: v.string(),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("subjects", {
      userId: args.userId,
      name: args.name,
      code: args.code,
      description: args.description,
      createdAt: Date.now(),
    });
  },
});

export const update = internalMutation({
  args: {
    id: v.id("subjects"),
    userId: v.id("users"),
    name: v.string(),
    code: v.string(),
    description: v.string(),
  },
  handler: async (ctx, args) => {
    const doc = await ctx.db.get(args.id);
    if (!doc || doc.userId !== args.userId) throw new Error("Subject not found");
    await ctx.db.patch(args.id, {
      name: args.name,
      code: args.code,
      description: args.description,
    });
  },
});

export const remove = internalMutation({
  args: { id: v.id("subjects"), userId: v.id("users") },
  handler: async (ctx, args) => {
    const doc = await ctx.db.get(args.id);
    if (!doc || doc.userId !== args.userId) throw new Error("Subject not found");

    // delete everything that belongs to this subject so we don't leave orphans
    const assignments = await ctx.db
      .query("assignments")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();
    for (const a of assignments) {
      if (a.subjectId === args.id) await ctx.db.delete(a._id);
    }

    const sessions = await ctx.db
      .query("studySessions")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .collect();
    for (const s of sessions) {
      if (s.subjectId === args.id) await ctx.db.delete(s._id);
    }

    await ctx.db.delete(args.id);
  },
});
