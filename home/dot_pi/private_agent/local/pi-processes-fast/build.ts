import { mkdtempSync, mkdirSync, readFileSync, renameSync, rmSync, writeFileSync, realpathSync, lstatSync } from "node:fs";
import { dirname, join, relative, resolve, extname } from "node:path";
import { createRequire } from "node:module";
const { parse } = createRequire(resolve(__dirname, "../../npm/package.json"))("acorn");
import { cacheKey, cacheRoot, currentInputs, fileDigest, inside, inventory, isExternal, options, packagePaths, same, select, sourceEntries, trusted, type Manifest, type Runtime } from "./cache";

const argument = process.argv[2];
if (argument === "--runtime") {
  const { runtimeIdentity } = await import("./cache");
  console.log(JSON.stringify(runtimeIdentity()));
  process.exit(0);
}
if (!argument) throw new Error("Usage: bun build.ts '<JSON from runtimeIdentity() inside Pi>'");
const runtime: Runtime = JSON.parse(argument.startsWith("{") ? argument : readFileSync(argument, "utf8"));
if (typeof runtime.execPath !== "string" || realpathSync(runtime.execPath) !== runtime.execPath || !runtime.versions ||
    Object.values(runtime.versions).some(value => typeof value !== "string") || !runtime.versions.bun ||
    !runtime.versions.node || !Number.isFinite(runtime.size) || !Number.isFinite(runtime.mtimeMs)) throw new Error("Invalid Pi runtime identity");
const runtimeStat = lstatSync(runtime.execPath);
if (runtimeStat.size !== runtime.size || runtimeStat.mtimeMs !== runtime.mtimeMs) throw new Error("Pi executable changed");
runtime.versions = Object.fromEntries(Object.entries(runtime.versions).sort());
const inputs = currentInputs();
const key = cacheKey(inputs, runtime);
const sourcePackage = JSON.parse(readFileSync(join(packagePaths[0], "package.json"), "utf8"));
if (!same(sourcePackage.pi.extensions.map((path: string) => resolve(packagePaths[0], path)), sourceEntries)) throw new Error("Unsupported source entrypoints");
mkdirSync(cacheRoot, { recursive: true, mode: 0o700 });
trusted(cacheRoot, true);
const temporary = mkdtempSync(join(cacheRoot, ".build-"));
const actualInputs = new Set<string>();
const allowed = new Set(inputs.map(input => input.path));
function check(code: string, path: string): { path: string }[] {
  const imports: { path: string }[] = [];
  function visit(node: any) {
    if (!node || typeof node !== "object") return;
    if (node.type === "ImportExpression" || node.type === "MetaProperty" ||
        ((node.type === "CallExpression" || node.type === "NewExpression") && ["require", "Worker", "createRequire"].includes(node.callee?.name)) ||
        (node.type === "MemberExpression" && ["Worker", "createRequire", "require"].includes(node.property?.name))) throw new Error(`Unsupported runtime loading: ${path}`);
    if (["ImportDeclaration", "ExportNamedDeclaration", "ExportAllDeclaration"].includes(node.type) && node.source) imports.push({ path: node.source.value });
    for (const value of Object.values(node)) if (Array.isArray(value)) value.forEach(visit); else if (value && typeof value === "object") visit(value);
  }
  visit(parse(code, { ecmaVersion: "latest", sourceType: "module" }));
  return imports;
}
try {
  const result = await Bun.build({
    ...options, entrypoints: sourceEntries, root: packagePaths[0], outdir: temporary,
    naming: { entry: "[dir]/[name].js", chunk: "chunks/[name]-[hash].js" },
    plugins: [{ name: "bounded-processes-inputs", setup(build) {
      build.onResolve({ filter: /.*/ }, args => {
        if (isExternal(args.path)) return { path: args.path, external: true };
        const path = realpathSync(Bun.resolveSync(args.path, args.importer ? dirname(args.importer) : packagePaths[0]));
        if (!allowed.has(path) || !packagePaths.some(root => inside(root, path))) throw new Error(`Unknown runtime input: ${path}`);
        return { path };
      });
      build.onLoad({ filter: /.*/ }, args => {
        if (!allowed.has(args.path) || !packagePaths.some(root => inside(root, args.path))) throw new Error(`Unknown build input: ${args.path}`);
        const code = readFileSync(args.path, "utf8");
        const extension = extname(args.path);
        if (![".ts", ".js", ".mjs", ".json"].includes(extension)) throw new Error(`Unsupported input format: ${args.path}`);
        if (fileDigest(args.path) !== inputs.find(input => input.path === args.path)?.digest) throw new Error("Input changed during build");
        actualInputs.add(args.path);
        return { contents: code, loader: extension === ".ts" ? "ts" : extension === ".json" ? "json" : "js" };
      });
    } }],
  });
  if (!result.success) throw new Error(result.logs.join("\n"));
  const entries = sourceEntries.map(path => relative(packagePaths[0], path).replace(/\.ts$/, ".js"));
  if (result.outputs.filter(output => output.kind === "entry-point").length !== 3 ||
      entries.some(entry => !result.outputs.some(output => relative(temporary, output.path) === entry && output.kind === "entry-point"))) throw new Error("Unexpected Bun entry metadata");
  for (const output of result.outputs) {
    if (!["entry-point", "chunk"].includes(output.kind)) throw new Error(`Unsupported output: ${output.kind}`);
    for (const item of check(await output.text(), output.path)) {
      if (isExternal(item.path)) continue;
      if (!item.path.startsWith(".") || !result.outputs.some(other => other.path === resolve(dirname(output.path), item.path))) throw new Error(`Unknown emitted import: ${item.path}`);
    }
  }
  if (!same(currentInputs(), inputs)) throw new Error("Inputs changed during build");
  const outputs = inventory([temporary]).map(file => ({ path: relative(temporary, file.path), digest: file.digest }));
  const builderPath = realpathSync(process.execPath);
  const manifest: Manifest = { schema: 1, key, runtime, inputs, outputs, entries, actualInputs: [...actualInputs].sort(),
    builder: { version: Bun.version, execPath: builderPath, digest: fileDigest(builderPath) } };
  writeFileSync(join(temporary, "manifest.json"), JSON.stringify(manifest));
  try { renameSync(temporary, join(cacheRoot, key)); }
  catch (error) { if (select(runtime).kind !== "cache") throw error; }
  if (select(runtime).kind !== "cache") throw new Error("Published cache failed validation");
  console.log(JSON.stringify({ key, directory: join(cacheRoot, key), entries, inputCount: inputs.length, actualInputCount: actualInputs.size, outputCount: outputs.length, builder: manifest.builder }));
} finally { rmSync(temporary, { recursive: true, force: true }); }
