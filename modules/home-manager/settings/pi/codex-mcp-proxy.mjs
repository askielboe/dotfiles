import { spawn } from "node:child_process";
import { createInterface } from "node:readline";

const [command, ...args] = process.argv.slice(2);
if (!command) throw new Error("Expected an MCP server command");
const child = spawn(command, args, { stdio: ["pipe", "pipe", "inherit"] });
child.stdout.pipe(process.stdout);

const input = createInterface({ input: process.stdin });
child.on("error", (error) => {
  console.error(error.message);
  process.exit(1);
});
child.on("exit", (code, signal) => {
  process.exit(code ?? (signal ? 1 : 0));
});
for (const signal of ["SIGTERM", "SIGINT"]) {
  process.on(signal, () => child.kill(signal));
}
process.on("exit", () => child.kill());

for await (const line of input) {
  const message = JSON.parse(line);
  if (message.method === "tools/call") {
    const params = message.params;
    const metadata = params.arguments?.__piCodexMetadata;
    if (metadata) {
      delete params.arguments.__piCodexMetadata;
      // Transport metadata must not become a model-visible tool argument.
      params._meta = {
        ...params._meta,
        "x-codex-turn-metadata": params._meta?.["x-codex-turn-metadata"] ?? metadata,
      };
    }
  }
  if (!child.stdin.write(`${JSON.stringify(message)}\n`)) {
    await new Promise((resolve) => child.stdin.once("drain", resolve));
  }
}
child.stdin.end();
