import { httpActionGeneric, httpRouter } from "convex/server";
import type { GenericActionCtx } from "convex/server";
import { internal } from "./_generated/api";
import type { Id } from "./_generated/dataModel";
import { HttpError, checkPassword, hashPassword, json, newToken } from "./lib";

const http = httpRouter();

// every route below is called by the Flutter app as POST <site-url>/api/....
// the logged in user is identified by the Authorization: Bearer <token> header

async function requireUser(ctx: any, request: any) {
  const auth = request.headers.get("Authorization") ?? "";
  const token = auth.replace("Bearer ", "").trim();
  if (!token) throw new HttpError(401, "Not logged in");
  const user = await ctx.runQuery(internal.users.findByToken, { token });
  if (!user) throw new HttpError(401, "Session expired, please login again");
  return user;
}

async function body(request: any) {
  try {
    return await request.json();
  } catch {
    throw new HttpError(400, "Invalid request body");
  }
}

function str(value: any, field: string, max = 500): string {
  if (typeof value !== "string" || value.trim() === "") {
    throw new HttpError(400, `${field} is required`);
  }
  if (value.length > max) throw new HttpError(400, `${field} is too long`);
  return value.trim();
}

// wraps a route so every error comes back as { error: "..." }
type Handler = (ctx: GenericActionCtx<any>, request: Request) => Promise<Response>;

function route(path: string, handler: Handler) {
  http.route({
    path,
    method: "POST",
    handler: httpActionGeneric(async (ctx, request) => {
      try {
        return await handler(ctx, request);
      } catch (err) {
        if (err instanceof HttpError) return json({ error: err.message }, err.status);
        // errors thrown inside mutations reach us as plain errors, not HttpError
        const msg = err instanceof Error ? err.message : "";
        if (msg.includes("not found")) {
          const clean = msg.split("\n")[0].replace("Uncaught Error: ", "").trim();
          return json({ error: clean || "Not found" }, 404);
        }
        console.error(path, err);
        return json({ error: "Something went wrong, try again" }, 500);
      }
    }),
  });
}

// ---------------------------------------------------------------------------
// auth
// ---------------------------------------------------------------------------

route("/api/auth/register", async (ctx, request) => {
  const b = await body(request);
  const name = str(b.name, "Name", 80);
  const email = str(b.email, "Email", 120).toLowerCase();
  const password = str(b.password, "Password", 100);

  if (!email.includes("@")) throw new HttpError(400, "Enter a valid email");
  if (password.length < 6) throw new HttpError(400, "Password must be at least 6 characters");

  const existing = await ctx.runQuery(internal.users.findByEmail, { email });
  if (existing) throw new HttpError(409, "This email is already registered");

  const token = newToken();
  const passwordHash = await hashPassword(password, crypto.randomUUID());
  const userId = await ctx.runMutation(internal.users.create, {
    name,
    email,
    passwordHash,
    token,
  });

  return json({ userId, name, email, token });
});

route("/api/auth/login", async (ctx, request) => {
  const b = await body(request);
  const email = str(b.email, "Email", 120).toLowerCase();
  const password = str(b.password, "Password", 100);

  const user = await ctx.runQuery(internal.users.findByEmail, { email });
  if (!user) throw new HttpError(401, "Email or password is wrong");

  const ok = await checkPassword(password, user.passwordHash);
  if (!ok) throw new HttpError(401, "Email or password is wrong");

  const token = newToken();
  await ctx.runMutation(internal.users.setToken, { userId: user._id, token });

  return json({ userId: user._id, name: user.name, email: user.email, token });
});

route("/api/auth/logout", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  await ctx.runMutation(internal.users.clearToken, { userId: user._id });
  return json({ ok: true });
});

// ---------------------------------------------------------------------------
// subjects
// ---------------------------------------------------------------------------

route("/api/subjects/list", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const subjects = await ctx.runQuery(internal.subjects.list, { userId: user._id });
  return json({ subjects });
});

route("/api/subjects/add", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);
  const name = str(b.name, "Subject name", 80);
  const code = typeof b.code === "string" ? b.code.trim().slice(0, 20) : "";
  const description = typeof b.description === "string" ? b.description.trim().slice(0, 300) : "";

  const id = await ctx.runMutation(internal.subjects.add, {
    userId: user._id,
    name,
    code,
    description,
  });
  return json({ id });
});

route("/api/subjects/update", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);
  const id = str(b.id, "Subject id", 60) as Id<"subjects">;
  const name = str(b.name, "Subject name", 80);
  const code = typeof b.code === "string" ? b.code.trim().slice(0, 20) : "";
  const description = typeof b.description === "string" ? b.description.trim().slice(0, 300) : "";

  await ctx.runMutation(internal.subjects.update, { id, userId: user._id, name, code, description });
  return json({ ok: true });
});

route("/api/subjects/delete", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);
  const id = str(b.id, "Subject id", 60) as Id<"subjects">;
  await ctx.runMutation(internal.subjects.remove, { id, userId: user._id });
  return json({ ok: true });
});

// ---------------------------------------------------------------------------
// assignments
// ---------------------------------------------------------------------------

route("/api/assignments/list", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const assignments = await ctx.runQuery(internal.assignments.list, { userId: user._id });
  return json({ assignments });
});

route("/api/assignments/add", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);

  const id = await ctx.runMutation(internal.assignments.add, {
    userId: user._id,
    subjectId: str(b.subjectId, "Subject", 60) as Id<"subjects">,
    title: str(b.title, "Title", 150),
    description: typeof b.description === "string" ? b.description.trim().slice(0, 2000) : "",
    dueDate: typeof b.dueDate === "number" ? b.dueDate : 0,
    priority: b.priority === "medium" || b.priority === "low" ? b.priority : "high",
    status: b.status === "completed" ? "completed" : "pending",
  });
  if (!id) throw new HttpError(400, "Could not save assignment");
  return json({ id });
});

route("/api/assignments/update", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);

  await ctx.runMutation(internal.assignments.update, {
    id: str(b.id, "Assignment id", 60) as Id<"assignments">,
    userId: user._id,
    subjectId: str(b.subjectId, "Subject", 60) as Id<"subjects">,
    title: str(b.title, "Title", 150),
    description: typeof b.description === "string" ? b.description.trim().slice(0, 2000) : "",
    dueDate: typeof b.dueDate === "number" ? b.dueDate : 0,
    priority: b.priority === "medium" || b.priority === "low" ? b.priority : "high",
    status: b.status === "completed" ? "completed" : "pending",
  });
  return json({ ok: true });
});

// quick status flip from the checkbox (pending <-> completed)
route("/api/assignments/status", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);
  await ctx.runMutation(internal.assignments.setStatus, {
    id: str(b.id, "Assignment id", 60) as Id<"assignments">,
    userId: user._id,
    status: b.status === "completed" ? "completed" : "pending",
  });
  return json({ ok: true });
});

route("/api/assignments/delete", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);
  await ctx.runMutation(internal.assignments.remove, {
    id: str(b.id, "Assignment id", 60) as Id<"assignments">,
    userId: user._id,
  });
  return json({ ok: true });
});

// ---------------------------------------------------------------------------
// study sessions
// ---------------------------------------------------------------------------

route("/api/sessions/list", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const sessions = await ctx.runQuery(internal.studySessions.list, { userId: user._id });
  return json({ sessions });
});

route("/api/sessions/add", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);
  const duration = typeof b.duration === "number" ? Math.round(b.duration) : 0;
  if (duration <= 0 || duration > 24 * 60) throw new HttpError(400, "Duration looks wrong");

  const id = await ctx.runMutation(internal.studySessions.add, {
    userId: user._id,
    subjectId: str(b.subjectId, "Subject", 60) as Id<"subjects">,
    duration,
    studyDate: typeof b.studyDate === "number" ? b.studyDate : Date.now(),
  });
  return json({ id });
});

route("/api/sessions/delete", async (ctx, request) => {
  const user = await requireUser(ctx, request);
  const b = await body(request);
  await ctx.runMutation(internal.studySessions.remove, {
    id: str(b.id, "Session id", 60) as Id<"studySessions">,
    userId: user._id,
  });
  return json({ ok: true });
});

// simple health check so the app can verify the backend url
route("/api/ping", async () => {
  return json({ ok: true, app: "StudyMate" });
});

// browser sends a preflight OPTIONS request before every api call
http.route({
  pathPrefix: "/api/",
  method: "OPTIONS",
  handler: httpActionGeneric(async () => {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "content-type, authorization",
        "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
      },
    });
  }),
});

export default http;
