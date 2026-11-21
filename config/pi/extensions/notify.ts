/**
 * Hooks pi into the shared agent notification stack (scripts/agent-notify.sh
 * and scripts/agent-state.sh), like claude-notify.sh and opencode-notify.sh:
 * tmux banner or dunst popup, the prefix+g pane jump, and the tab spinner.
 *
 *   agent_start      -> agent-state.sh working Pi
 *   ui_prompt_start  -> agent-notify.sh Pi notification   (input needed)
 *   agent_settled    -> agent-notify.sh Pi stop           (turn complete)
 */

import { spawn } from "node:child_process";
import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// ~/.config/pi is a symlink to <repo>/config/pi (install.sh); the scripts sit
// next to it in <repo>/scripts.
function scriptsDir(): string | undefined {
	try {
		return join(realpathSync(join(homedir(), ".config", "pi")), "..", "..", "scripts");
	} catch {
		return undefined;
	}
}

function run(script: string, args: string[], stdin?: string): void {
	const dir = scriptsDir();
	if (!dir) return;
	const child = spawn(join(dir, script), args, {
		stdio: [stdin === undefined ? "ignore" : "pipe", "ignore", "ignore"],
		detached: true,
	});
	child.on("error", () => {});
	if (stdin !== undefined) child.stdin?.end(stdin);
	child.unref();
}

export default function (pi: ExtensionAPI) {
	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.hasUI) run("agent-state.sh", ["working", "Pi"]);
	});

	pi.on("ui_prompt_start", async (event, ctx) => {
		if (!ctx.hasUI) return;
		run("agent-notify.sh", ["Pi", "notification"], JSON.stringify({ message: event.title || "Input needed" }));
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (ctx.hasUI) run("agent-notify.sh", ["Pi", "stop"]);
	});
}
