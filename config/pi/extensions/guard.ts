/**
 * pi has no permission prompts. This adds the few that matter here:
 *   - git commit / push / tag, and pushes through gh/glab: confirm first
 *     (rule: never commit or push unless asked)
 *   - reading credential files in $AGENT_SECRETS: always blocked; use them in
 *     place (curl -K "$AGENT_SECRETS/x.curl"), never print them
 * Without a UI (pi -p, RPC) anything that would prompt is blocked.
 */

import { isToolCallEventType, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SECRETS = process.env.AGENT_SECRETS || "/run/secrets";

const CONFIRM: [RegExp, string][] = [
	[/\bgit\b[^|;&]*\s(commit|push|tag)\b/, "git commit/push/tag"],
	[/\b(gh|glab)\s+(pr|mr)\s+(create|merge)\b/, "opening or merging a PR/MR"],
];

// Commands that would dump a secret file's contents.
const SECRET_DUMP = new RegExp(
	String.raw`\b(cat|less|more|head|tail|bat|xxd|od|strings|base64|cp|scp|rsync)\b[^|;&]*(\$\{?AGENT_SECRETS\}?|` +
		SECRETS.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") +
		")",
);

function isSecretPath(p: string): boolean {
	return p === SECRETS || p.startsWith(`${SECRETS}/`) || p.includes("$AGENT_SECRETS");
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (isToolCallEventType("read", event) && isSecretPath(event.input.path)) {
			return { block: true, reason: `Do not read credential files; use them in place (e.g. curl -K "$AGENT_SECRETS/<name>")` };
		}

		if (!isToolCallEventType("bash", event)) return undefined;
		const cmd = event.input.command;

		if (SECRET_DUMP.test(cmd)) {
			return { block: true, reason: "Do not print or copy credential files; use them in place" };
		}

		const hit = CONFIRM.find(([re]) => re.test(cmd));
		if (!hit) return undefined;
		if (!ctx.hasUI) return { block: true, reason: `${hit[1]} needs confirmation (no UI)` };

		const ok = await ctx.ui.confirm(`Allow ${hit[1]}?`, cmd);
		return ok ? undefined : { block: true, reason: `${hit[1]} not approved by the user` };
	});
}
