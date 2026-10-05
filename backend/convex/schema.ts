import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

// Database tables - same as the schema I designed in my project report
export default defineSchema({
  users: defineTable({
    name: v.string(),
    email: v.string(),
    passwordHash: v.string(), // salt$sha256hash
    token: v.optional(v.string()), // session token after login
    createdAt: v.number(),
  }).index("by_email", ["email"]).index("by_token", ["token"]),

  subjects: defineTable({
    userId: v.id("users"),
    name: v.string(),
    code: v.string(),
    description: v.string(),
    createdAt: v.number(),
  }).index("by_user", ["userId"]),

  assignments: defineTable({
    userId: v.id("users"),
    subjectId: v.id("subjects"),
    title: v.string(),
    description: v.string(),
    dueDate: v.number(), // ms timestamp (midnight of the due day)
    priority: v.union(v.literal("high"), v.literal("medium"), v.literal("low")),
    status: v.union(v.literal("pending"), v.literal("completed")),
    createdAt: v.number(),
  }).index("by_user", ["userId"]),

  studySessions: defineTable({
    userId: v.id("users"),
    subjectId: v.id("subjects"),
    duration: v.number(), // minutes
    studyDate: v.number(), // ms timestamp of the day studied
    createdAt: v.number(),
  }).index("by_user", ["userId"]),
});
