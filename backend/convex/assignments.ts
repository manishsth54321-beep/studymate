import { v } from "convex/values";
import { internalMutation, internalQuery } from "./_generated/server";

// assignments table operations

export const list = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("assignments")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("desc")
      .collect();
  },
});

export const add = internalMutation({
  args: {
    userId: v.id("users"),
    subjectId: v.id("subjects"),
    title: v.string(),
    description: v.string(),
    dueDate: v.number(),
    priority: v.union(v.literal("high"), v.literal("medium"), v.literal("low")),
    status: v.union(v.literal("pending"), v.literal("completed")),
  },
  handler: async (ctx, args) => {
    // make sure the subject really belongs to this user
    const subject = await ctx.db.get(args.subjectId);
    if (!subject || subject.userId !== args.userId) throw new Error("Subject not found");

    return await ctx.db.insert("assignments", {
      userId: args.userId,
      subjectId: args.subjectId,
      title: args.title,
      description: args.description,
      dueDate: args.dueDate,
      priority: args.priority,
      status: args.status,
      createdAt: Date.now(),
    });
  },
});

export const update = internalMutation({
  args: {
    id: v.id("assignments"),
    userId: v.id("users"),
    subjectId: v.id("subjects"),
    title: v.string(),
    description: v.string(),
    dueDate: v.number(),
    priority: v.union(v.literal("high"), v.literal("medium"), v.literal("low")),
    status: v.union(v.literal("pending"), v.literal("completed")),
  },
  handler: async (ctx, args) => {
    const doc = await ctx.db.get(args.id);
    if (!doc || doc.userId !== args.userId) throw new Error("Assignment not found");
    await ctx.db.patch(args.id, {
      subjectId: args.subjectId,
      title: args.title,
      description: args.description,
      dueDate: args.dueDate,
      priority: args.priority,
      status: args.status,
    });
  },
});

// used by the checkbox on the task list - only flips the status
export const setStatus = internalMutation({
  args: {
    id: v.id("assignments"),
    userId: v.id("users"),
    status: v.union(v.literal("pending"), v.literal("completed")),
  },
  handler: async (ctx, args) => {
    const doc = await ctx.db.get(args.id);
    if (!doc || doc.userId !== args.userId) throw new Error("Assignment not found");
    await ctx.db.patch(args.id, { status: args.status });
  },
});

export const remove = internalMutation({
  args: { id: v.id("assignments"), userId: v.id("users") },
  handler: async (ctx, args) => {
    const doc = await ctx.db.get(args.id);
    if (!doc || doc.userId !== args.userId) throw new Error("Assignment not found");
    await ctx.db.delete(args.id);
  },
});
