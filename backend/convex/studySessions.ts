import { v } from "convex/values";
import { internalMutation, internalQuery } from "./_generated/server";

// study sessions table - each row is one study log (subject + minutes)

export const list = internalQuery({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("studySessions")
      .withIndex("by_user", (q) => q.eq("userId", args.userId))
      .order("desc")
      .collect();
  },
});

export const add = internalMutation({
  args: {
    userId: v.id("users"),
    subjectId: v.id("subjects"),
    duration: v.number(),
    studyDate: v.number(),
  },
  handler: async (ctx, args) => {
    const subject = await ctx.db.get(args.subjectId);
    if (!subject || subject.userId !== args.userId) throw new Error("Subject not found");

    return await ctx.db.insert("studySessions", {
      userId: args.userId,
      subjectId: args.subjectId,
      duration: args.duration,
      studyDate: args.studyDate,
      createdAt: Date.now(),
    });
  },
});

export const remove = internalMutation({
  args: { id: v.id("studySessions"), userId: v.id("users") },
  handler: async (ctx, args) => {
    const doc = await ctx.db.get(args.id);
    if (!doc || doc.userId !== args.userId) throw new Error("Session not found");
    await ctx.db.delete(args.id);
  },
});
