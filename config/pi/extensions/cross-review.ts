/**
 * /xreview [provider/model]
 *
 * Sends the working-tree diff (git diff HEAD) to a second model, by default
 * one from the *other* provider than the active model (Codex writes, Claude
 * reviews, or the reverse), and drops the findings into the session so the
 * main model can act on them ("fix 1 and 3").
 */

import { uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

const MAX_DIFF_CHARS = 200_000;

const PROMPT = `You are reviewing a diff written by another model. Report only real problems:
bugs, wrong behavior, broken edge cases, security issues, and contracts that no longer hold.
No style nits, no praise, no restating the diff. For each finding give file:line, what breaks,
and the fix in one or two sentences. Number the findings. If nothing is wrong, say "No findings."`;

// Picks a reviewer: the explicit provider/model, else the first available
// model from a provider other than the active one.
function pickReviewer(ctx: ExtensionCommandContext, arg: string) {
	if (arg) {
		const [provider, ...rest] = arg.split("/");
		return rest.length ? ctx.modelRegistry.find(provider, rest.join("/")) : undefined;
	}
	const current = ctx.model?.provider;
	return ctx.modelRegistry
		.getAvailable()
		.find((m) => m.provider !== current && ["anthropic", "openai", "openai-codex"].includes(m.provider));
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("xreview", {
		description: "Review the current git diff with the other provider's model",
		handler: async (args, ctx) => {
			const diff = await pi.exec("git", ["diff", "HEAD"], { cwd: ctx.cwd, timeout: 15_000 });
			if (diff.code !== 0) return ctx.ui.notify(`git diff failed: ${diff.stderr.trim()}`, "error");
			if (!diff.stdout.trim()) return ctx.ui.notify("No changes against HEAD", "info");

			const model = pickReviewer(ctx, args.trim());
			if (!model) return ctx.ui.notify("No reviewer model found; pass provider/model or /login to the other provider", "warning");
			if (!ctx.modelRegistry.hasConfiguredAuth(model)) {
				return ctx.ui.notify(`No auth for ${model.provider}/${model.id}; run /login`, "warning");
			}

			const text = diff.stdout.length > MAX_DIFF_CHARS ? `${diff.stdout.slice(0, MAX_DIFF_CHARS)}\n[diff truncated]` : diff.stdout;
			ctx.ui.notify(`Reviewing with ${model.provider}/${model.id}...`, "info");

			const res = await ctx.modelRegistry.complete(
				model,
				{
					messages: [
						{
							role: "user" as const,
							content: [{ type: "text" as const, text: `${PROMPT}\n\n<diff>\n${text}\n</diff>` }],
							timestamp: Date.now(),
						},
					],
				},
				{ reasoningEffort: "high", cacheRetention: "none", sessionId: uuidv7() },
			);
			const findings = res.content
				.filter((c): c is { type: "text"; text: string } => c.type === "text")
				.map((c) => c.text)
				.join("\n")
				.trim();

			pi.sendMessage(
				{
					customType: "cross-review",
					content: `Review of the current diff by ${model.provider}/${model.id}:\n\n${findings || "(empty response)"}`,
					display: true,
				},
				{ triggerTurn: false },
			);
		},
	});
}
