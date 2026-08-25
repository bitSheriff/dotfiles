/**
 * Pure helpers for the /context breakdown. No pi-runtime imports so they're unit-testable.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export function estimateTokens(text: string): number {
	// Deliberately fuzzy (good enough for “how big-ish is this”).
	return Math.max(0, Math.ceil(text.length / 4));
}

export type ToolInfo = ReturnType<ExtensionAPI["getAllTools"]>[number];

function decodeXmlEntities(s: string): string {
	return s
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&quot;/g, '"')
		.replace(/&apos;/g, "'")
		.replace(/&amp;/g, "&");
}

/**
 * Split the assembled system prompt into three regions by literal markers:
 *  - memory: <project_context> … </project_context>   (CLAUDE.md / AGENTS.md)
 *  - skills: "The following skills provide…" … </available_skills>
 *  - system: everything else (custom prompt + pi base + appended preambles)
 * Missing regions come back as "". `system` is the original with the other two removed.
 */
export function sliceSystemPrompt(prompt: string): { system: string; memory: string; skills: string } {
	let system = prompt ?? "";
	let memory = "";
	let skills = "";

	const memStart = system.indexOf("<project_context>");
	if (memStart !== -1) {
		const marker = "</project_context>";
		const idx = system.indexOf(marker, memStart);
		if (idx !== -1) {
			const end = idx + marker.length;
			memory = system.slice(memStart, end);
			system = system.slice(0, memStart) + system.slice(end);
		}
	}

	const skillsStart = system.indexOf("The following skills provide specialized instructions for specific tasks.");
	if (skillsStart !== -1) {
		const marker = "</available_skills>";
		const idx = system.indexOf(marker, skillsStart);
		if (idx !== -1) {
			const end = idx + marker.length;
			skills = system.slice(skillsStart, end);
			system = system.slice(0, skillsStart) + system.slice(end);
		}
	}

	return { system, memory, skills };
}

/** Real injected size of one tool: name + description + parameters schema + guidelines, as JSON. */
export function toolDefTokens(tool: ToolInfo): number {
	const blob = JSON.stringify({
		name: tool.name,
		description: tool.description,
		parameters: tool.parameters,
		promptGuidelines: tool.promptGuidelines,
	});
	return estimateTokens(blob);
}

/** Per-active-tool token cost, sorted largest first. Inactive tools are excluded. */
export function sumToolTokens(
	tools: ToolInfo[],
	activeNames: string[],
): { total: number; perTool: { name: string; tokens: number }[] } {
	const byName = new Map(tools.map((t) => [t.name, t] as const));
	const perTool: { name: string; tokens: number }[] = [];
	let total = 0;
	for (const name of activeNames) {
		const info = byName.get(name);
		const tokens = info ? toolDefTokens(info) : estimateTokens(name);
		perTool.push({ name, tokens });
		total += tokens;
	}
	perTool.sort((a, b) => b.tokens - a.tokens || a.name.localeCompare(b.name));
	return { total, perTool };
}

/** Per-skill token cost from the sliced skills region, sorted largest first. */
export function skillBreakdown(skillsRegion: string): { total: number; perSkill: { name: string; tokens: number }[] } {
	const perSkill: { name: string; tokens: number }[] = [];
	let total = 0;
	const re = /<skill>[\s\S]*?<\/skill>/g;
	let m: RegExpExecArray | null;
	while ((m = re.exec(skillsRegion ?? "")) !== null) {
		const block = m[0];
		const nameMatch = block.match(/<name>([\s\S]*?)<\/name>/);
		const name = nameMatch ? decodeXmlEntities(nameMatch[1].trim()) : "(unknown)";
		const tokens = estimateTokens(block);
		perSkill.push({ name, tokens });
		total += tokens;
	}
	perSkill.sort((a, b) => b.tokens - a.tokens || a.name.localeCompare(b.name));
	return { total, perSkill };
}

export type ContextCategory = { label: string; tokens: number; pct: number };

export type ScaleSource = "usage" | "cache" | "raw";

/**
 * Decompose the real context total into categories.
 *
 * Providers return an exact TOTAL (`usage`) but no category breakdown. `char/4` gives the
 * proportions; we scale each char/4 category by `scale = realTotal / char4Total` so the slices
 * sum to the provider's real number. This is model-agnostic with no hardcoded constants: the
 * scale lands ~1.55 on Anthropic, ~1.05 on OpenAI, etc. Measured: the scale is stable across
 * conversation size (1.549–1.555 as messages grew 27→991 char/4 tokens), so a fresh session with
 * no `usage` yet reuses the model's last cached scale; with no cache it falls back to raw char/4
 * (scale 1) and self-corrects on the first reply.
 *
 * `realTotal` is `getContextUsage().tokens` (pi's authoritative gauge, = last assistant's real
 * provider total + char/4 of trailing messages). `null` when unknown (fresh / post-compaction).
 * `messagesTok` is the char/4 estimate of the conversation (NOT a residual).
 */
export function buildScaledBreakdown(input: {
	systemTok: number;
	memoryTok: number;
	skillsTok: number;
	toolsTok: number;
	messagesTok: number;
	realTotal: number | null;
	cachedScale: number | null;
	contextWindow: number;
}): {
	categories: ContextCategory[];
	scale: number;
	scaleSource: ScaleSource;
	effective: number;
	contextWindow: number;
	free: number;
} {
	const { systemTok, memoryTok, skillsTok, toolsTok, messagesTok, realTotal, cachedScale, contextWindow } = input;
	const char4Total = systemTok + memoryTok + skillsTok + toolsTok + messagesTok;

	let scale: number;
	let scaleSource: ScaleSource;
	if (realTotal && realTotal > 0 && char4Total > 0) {
		scale = realTotal / char4Total;
		scaleSource = "usage";
	} else if (cachedScale && cachedScale > 0) {
		scale = cachedScale;
		scaleSource = "cache";
	} else {
		scale = 1;
		scaleSource = "raw";
	}
	if (!Number.isFinite(scale) || scale <= 0) scale = 1;

	const sc = (n: number) => Math.round(n * scale);
	const sys = sc(systemTok);
	const mem = sc(memoryTok);
	const sk = sc(skillsTok);
	const tl = sc(toolsTok);
	const msg = sc(messagesTok);
	const effective = sys + mem + sk + tl + msg;
	const free = contextWindow > 0 ? Math.max(0, contextWindow - effective) : 0;
	const pctOf = (n: number) => (contextWindow > 0 ? (n / contextWindow) * 100 : 0);

	const consumed: ContextCategory[] = [
		{ label: "System prompt", tokens: sys, pct: pctOf(sys) },
		{ label: "Tools", tokens: tl, pct: pctOf(tl) },
		{ label: "Memory files", tokens: mem, pct: pctOf(mem) },
		{ label: "Skills", tokens: sk, pct: pctOf(sk) },
		{ label: "Messages", tokens: msg, pct: pctOf(msg) },
	];
	consumed.sort((a, b) => b.tokens - a.tokens);
	const categories = [...consumed, { label: "Free space", tokens: free, pct: pctOf(free) }];
	return { categories, scale, scaleSource, effective, contextWindow, free };
}

const ESTIMATED_IMAGE_CHARS = 4800;

function contentChars(content: unknown): number {
	if (typeof content === "string") return content.length;
	if (Array.isArray(content)) {
		let chars = 0;
		for (const block of content) {
			const b = block as { type?: string; text?: string };
			if (b?.type === "text" && typeof b.text === "string") chars += b.text.length;
			else if (b?.type === "image") chars += ESTIMATED_IMAGE_CHARS;
		}
		return chars;
	}
	return 0;
}

/** char/4 of one conversation message, mirroring pi's compaction `estimateTokens(message)`. */
function oneMessageTokens(message: any): number {
	if (!message || typeof message !== "object") return 0;
	switch (message.role) {
		case "user":
		case "toolResult":
		case "custom":
			return Math.ceil(contentChars(message.content) / 4);
		case "assistant": {
			let chars = 0;
			for (const block of message.content ?? []) {
				if (block?.type === "text") chars += block.text?.length ?? 0;
				else if (block?.type === "thinking") chars += block.thinking?.length ?? 0;
				else if (block?.type === "toolCall") chars += (block.name?.length ?? 0) + JSON.stringify(block.arguments ?? {}).length;
			}
			return Math.ceil(chars / 4);
		}
		case "bashExecution":
			return Math.ceil(((message.command?.length ?? 0) + (message.output?.length ?? 0)) / 4);
		case "branchSummary":
		case "compactionSummary":
			return Math.ceil((message.summary?.length ?? 0) / 4);
		default:
			return 0;
	}
}

/**
 * char/4 estimate of all conversation messages from session entries. Mirrors pi's compaction
 * estimate so the "Messages" slice tracks what actually gets sent (excludes system + tools).
 */
export function estimateMessagesTokens(entries: Array<Record<string, any>>): number {
	let total = 0;
	for (const e of entries ?? []) {
		if (!e || typeof e !== "object") continue;
		if (e.type === "message") total += oneMessageTokens(e.message);
		else if (e.type === "custom_message") total += Math.ceil(String(e.content ?? "").length / 4);
		else if (e.type === "branch_summary") total += Math.ceil(String(e.summary ?? "").length / 4);
		else if (e.type === "compaction") total += Math.ceil(String(e.summary ?? "").length / 4);
	}
	return total;
}

/** Parse the per-model scale cache JSON. Tolerant of garbage → {}. Keeps only positive finite scales. */
export function parseScaleCache(json: string | null | undefined): Record<string, number> {
	if (!json) return {};
	try {
		const obj = JSON.parse(json);
		if (!obj || typeof obj !== "object" || Array.isArray(obj)) return {};
		const out: Record<string, number> = {};
		for (const [k, v] of Object.entries(obj)) {
			const n = typeof v === "number" ? v : Number(v);
			if (Number.isFinite(n) && n > 0) out[k] = n;
		}
		return out;
	} catch {
		return {};
	}
}

export function serializeScaleCache(cache: Record<string, number>): string {
	return JSON.stringify(cache, null, 2);
}
