export async function queryAll<T>(
  db: D1Database,
  query: string,
  ...bindings: unknown[]
): Promise<T[]> {
  const stmt = bindings.length > 0
    ? db.prepare(query).bind(...bindings)
    : db.prepare(query);
  const result = await stmt.all<T>();
  return result.results;
}

export async function queryFirst<T>(
  db: D1Database,
  query: string,
  ...bindings: unknown[]
): Promise<T | null> {
  const stmt = bindings.length > 0
    ? db.prepare(query).bind(...bindings)
    : db.prepare(query);
  return await stmt.first<T>();
}

export async function execute(
  db: D1Database,
  query: string,
  ...bindings: unknown[]
): Promise<D1Result> {
  const stmt = bindings.length > 0
    ? db.prepare(query).bind(...bindings)
    : db.prepare(query);
  return await stmt.run();
}
