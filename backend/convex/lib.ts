// small helpers used by the http routes

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      // so the app also works when run in a browser
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "content-type, authorization",
      "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    },
  });
}

// error I can throw from a route, carries the http status code
export class HttpError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

// sha256 of salt + password, stored as "salt$hash"
export async function hashPassword(password: string, salt: string): Promise<string> {
  const bytes = new TextEncoder().encode(salt + password);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  const hex = Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return `${salt}$${hex}`;
}

export function checkPassword(password: string, stored: string): Promise<boolean> {
  const [salt, hash] = stored.split("$");
  if (!salt || !hash) return Promise.resolve(false);
  return hashPassword(password, salt).then((h) => h === stored);
}

export function newToken(): string {
  return crypto.randomUUID().replaceAll("-", "");
}
