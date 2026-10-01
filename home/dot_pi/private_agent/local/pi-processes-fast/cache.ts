import { createHash } from "node:crypto";
import { lstatSync, readFileSync, readdirSync, realpathSync } from "node:fs";
import { builtinModules } from "node:module";
import { join, relative, resolve } from "node:path";
import { tmpdir } from "node:os";

export type Selection = { kind: "source" | "cache"; entries: string[] };
export type Runtime = { execPath: string; versions: Record<string, string>; size: number; mtimeMs: number };
export type Inventory = { path: string; digest: string }[];
export type Manifest = {
  schema: 1; key: string; runtime: Runtime; inputs: Inventory; outputs: Inventory;
  entries: string[]; actualInputs: string[];
  builder: { version: string; execPath: string; digest: string };
};
export const home = resolve(__dirname);
export const names = ["pi-processes", "pi-utils-settings", "pi-utils-ui", "sh"];
export const packagePaths = names.map(name => resolve(home, "../../npm/node_modules/@aliou", name));
export const sourceEntries = ["processes", "processes-logs", "processes-dock"].map(name => join(packagePaths[0], "extensions", name, "index.ts"));
export const options = { target: "node", format: "esm", splitting: true, minify: false } as const;
export const cacheRoot = join(tmpdir(), `pi-processes-fast-${process.getuid?.() ?? "unsupported"}`);
export function trusted(path: string, directory = false) {
  const stat = lstatSync(path);
  if (!process.getuid || stat.uid !== process.getuid() || stat.isSymbolicLink() ||
      (directory ? !stat.isDirectory() || (stat.mode & 0o777) !== 0o700 : !stat.isFile() || (stat.mode & 0o022) !== 0)) throw new Error(`Untrusted cache path: ${path}`);
}
const peers = ["@earendil-works/pi-agent-core", "@earendil-works/pi-ai", "@earendil-works/pi-coding-agent", "@earendil-works/pi-tui", "typebox"];
export const external = peers.flatMap(name => [name, `${name}/*`]);
export const isExternal = (name: string) => builtinModules.includes(name.replace(/^node:/, "")) || peers.some(peer => name === peer || name.startsWith(`${peer}/`));
export const digest = (data: string | Buffer) => createHash("sha256").update(data).digest("hex");
export const fileDigest = (path: string) => digest(readFileSync(path));
export const same = (a: unknown, b: unknown) => JSON.stringify(a) === JSON.stringify(b);
export function runtimeIdentity(): Runtime {
  const execPath = realpathSync(process.execPath);
  const stat = lstatSync(execPath);
  return { execPath, versions: Object.fromEntries(Object.entries(process.versions).sort()), size: stat.size, mtimeMs: stat.mtimeMs };
}
export function inventory(roots: string[]): Inventory {
  const files: Inventory = [];
  function visit(path: string) {
    const stat = lstatSync(path);
    if (stat.isSymbolicLink()) throw new Error(`Symlink input is unsupported: ${path}`);
    if (stat.isDirectory()) for (const name of readdirSync(path).sort()) visit(join(path, name));
    else if (stat.isFile()) files.push({ path, digest: fileDigest(path) });
    else throw new Error(`Unsupported input: ${path}`);
  }
  for (const root of roots) visit(root);
  return files.sort((a, b) => a.path.localeCompare(b.path));
}
export function currentInputs(): Inventory {
  return inventory([...packagePaths, ...["index.ts", "cache.ts", "build.ts", "package.json"].map(name => join(home, name)),
    ...["package.json", "package-lock.json", "node_modules/.package-lock.json", "node_modules/acorn/package.json", "node_modules/acorn/dist/acorn.js"].map(name => resolve(home, "../../npm", name))]);
}
export const cacheKey = (inputs: Inventory, runtime: Runtime) => digest(JSON.stringify({ schema: 1, inputs, runtime, options, sourceEntries }));
export const inside = (root: string, path: string) => { const rel = relative(root, path); return rel !== "" && !rel.startsWith("..") && !rel.startsWith("/"); };
export function select(runtime = runtimeIdentity(), root = cacheRoot): Selection {
  const source: Selection = { kind: "source", entries: sourceEntries };
  try {
    trusted(root, true);
    const sourcePackage = JSON.parse(readFileSync(join(packagePaths[0], "package.json"), "utf8"));
    if (!same(sourcePackage.pi.extensions.map((path: string) => resolve(packagePaths[0], path)), sourceEntries)) return source;
    const inputs = currentInputs();
    const key = cacheKey(inputs, runtime);
    const dir = join(root, key);
    trusted(dir, true);
    trusted(join(dir, "manifest.json"));
    const manifest: Manifest = JSON.parse(readFileSync(join(dir, "manifest.json"), "utf8"));
    if (manifest.schema !== 1 || manifest.key !== key || !same(manifest.runtime, runtime) || !same(manifest.inputs, inputs)) return source;
    if (!manifest.builder?.version || !manifest.builder.execPath?.startsWith("/") || !/^[a-f0-9]{64}$/.test(manifest.builder.digest)) return source;
    if (!Array.isArray(manifest.actualInputs) || !manifest.actualInputs.length || manifest.actualInputs.some(path => !inputs.some(input => input.path === path))) return source;
    const outputs = inventory([dir]).filter(file => file.path !== join(dir, "manifest.json"))
      .map(file => ({ path: relative(dir, file.path), digest: file.digest }));
    for (const output of outputs) trusted(join(dir, output.path));
    if (!outputs.length || !same(manifest.outputs, outputs)) return source;
    const expectedEntries = sourceEntries.map(path => relative(packagePaths[0], path).replace(/\.ts$/, ".js"));
    if (!same(manifest.entries, expectedEntries)) return source;
    if (manifest.entries.some(path => typeof path !== "string" || !inside(dir, resolve(dir, path)) || !outputs.some(output => output.path === path))) return source;
    return { kind: "cache", entries: manifest.entries.map(path => join(dir, path)) };
  } catch { return source; }
}
