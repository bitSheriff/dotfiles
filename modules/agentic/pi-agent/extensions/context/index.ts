/**
 * /context
 *
 * Small TUI view showing what's loaded/available:
 * - extensions (best-effort from registered extension slash commands)
 * - skills
 * - project context files (AGENTS.md / CLAUDE.md)
 * - current context window usage + session totals (tokens/cost)
 */

import type { ExtensionAPI, ExtensionCommandContext, ExtensionContext, ToolResultEvent } from "@earendil-works/pi-coding-agent";
import { DynamicBorder } from "@earendil-works/pi-coding-agent";
import { Container, Key, Text, matchesKey, type Component, type TUI } from "@earendil-works/pi-tui";
import os from "node:os";
import path from "node:path";
import fs from "node:fs/promises";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import {
	buildScaledBreakdown,
	type ContextCategory,
	estimateMessagesTokens,
	estimateTokens,
	parseScaleCache,
	serializeScaleCache,
	skillBreakdown,
	sliceSystemPrompt,
	sumToolTokens,
} from "./context-pure";

function formatUsd(cost: number): string {
	if (!Number.isFinite(cost) || cost <= 0) return "$0.00";
	if (cost >= 1) return `$${cost.toFixed(2)}`;
	if (cost >= 0.1) return `$${cost.toFixed(3)}`;
	return `$${cost.toFixed(4)}`;
}

const SCALE_CACHE_PATH = path.join(os.homedir(), ".pi", "agent", "context-scale-cache.json");

function readScaleCacheFile(): Record<string, number> {
	try {
		return parseScaleCache(readFileSync(SCALE_CACHE_PATH, "utf8"));
	} catch {
		return {};
	}
}

function writeScaleCacheFile(cache: Record<string, number>): void {
	try {
		writeFileSync(SCALE_CACHE_PATH, serializeScaleCache(cache));
	} catch {
		// best-effort; the cache is an optimization, not correctness-critical
	}
}

/** Short label describing how the total was derived (char/4 proportions scaled to the real total). */
function scaleLabel(scaleSource: "usage" | "cache" | "raw", scale: number): string {
	if (scaleSource === "usage") return `calibrated ×${scale.toFixed(2)}`;
	if (scaleSource === "cache") return `est. ×${scale.toFixed(2)} (last turn)`;
	return "≈ raw char/4 — calibrates after first reply";
}

function normalizeReadPath(inputPath: string, cwd: string): string {
	// Similar to pi's resolveToCwd/resolveReadPath, but simplified.
	let p = inputPath;
	if (p.startsWith("@")) p = p.slice(1);
	if (p === "~") p = os.homedir();
	else if (p.startsWith("~/")) p = path.join(os.homedir(), p.slice(2));
	if (!path.isAbsolute(p)) p = path.resolve(cwd, p);
	return path.resolve(p);
}

function getAgentDir(): string {
	// Mirrors pi's behavior reasonably well.
	const envCandidates = ["PI_CODING_AGENT_DIR", "TAU_CODING_AGENT_DIR"];
	let envDir: string | undefined;
	for (const k of envCandidates) {
		if (process.env[k]) {
			envDir = process.env[k];
			break;
		}
	}
	if (!envDir) {
		for (const [k, v] of Object.entries(process.env)) {
			if (k.endsWith("_CODING_AGENT_DIR") && v) {
				envDir = v;
				break;
			}
		}
	}

	if (envDir) {
		if (envDir === "~") return os.homedir();
		if (envDir.startsWith("~/")) return path.join(os.homedir(), envDir.slice(2));
		return envDir;
	}
	return path.join(os.homedir(), ".pi", "agent");
}

async function readFileIfExists(filePath: string): Promise<{ path: string; content: string; bytes: number } | null> {
	if (!existsSync(filePath)) return null;
	try {
		const buf = await fs.readFile(filePath);
		return { path: filePath, content: buf.toString("utf8"), bytes: buf.byteLength };
	} catch {
		return null;
	}
}

async function loadProjectContextFiles(cwd: string): Promise<Array<{ path: string; tokens: number; bytes: number }>> {
	const out: Array<{ path: string; tokens: number; bytes: number }> = [];
	const seen = new Set<string>();

	const loadFromDir = async (dir: string) => {
		for (const name of ["AGENTS.md", "CLAUDE.md"]) {
			const p = path.join(dir, name);
			const f = await readFileIfExists(p);
			if (f && !seen.has(f.path)) {
				seen.add(f.path);
				out.push({ path: f.path, tokens: estimateTokens(f.content), bytes: f.bytes });
				// pi loads at most one of those per dir
				return;
			}
		}
	};

	await loadFromDir(getAgentDir());

	// Ancestors: root → cwd (same order as pi)
	const stack: string[] = [];
	let current = path.resolve(cwd);
	while (true) {
		stack.push(current);
		const parent = path.resolve(current, "..");
		if (parent === current) break;
		current = parent;
	}
	stack.reverse();
	for (const dir of stack) await loadFromDir(dir);

	return out;
}

function normalizeSkillName(name: string): string {
	return name.startsWith("skill:") ? name.slice("skill:".length) : name;
}

type SkillIndexEntry = {
	name: string;
	skillFilePath: string;
	skillDir: string;
};

function buildSkillIndex(pi: ExtensionAPI, cwd: string): SkillIndexEntry[] {
	return pi
		.getCommands()
		.filter((c) => c.source === "skill")
		.map((c) => {
			const p = c.sourceInfo?.path ? normalizeReadPath(c.sourceInfo.path, cwd) : "";
			return {
				name: normalizeSkillName(c.name),
				skillFilePath: p,
				skillDir: p ? path.dirname(p) : "",
			};
		})
		.filter((x) => x.name && x.skillDir);
}

const SKILL_LOADED_ENTRY = "context:skill_loaded";

type SkillLoadedEntryData = {
	name: string;
	path: string;
};

function getLoadedSkillsFromSession(ctx: ExtensionContext): Set<string> {
	const out = new Set<string>();
	for (const e of ctx.sessionManager.getEntries()) {
		if ((e as any)?.type !== "custom") continue;
		if ((e as any)?.customType !== SKILL_LOADED_ENTRY) continue;
		const data = (e as any)?.data as SkillLoadedEntryData | undefined;
		if (data?.name) out.add(data.name);
	}
	return out;
}

function extractCostTotal(usage: any): number {
	if (!usage) return 0;
	const c = usage?.cost;
	if (typeof c === "number") return Number.isFinite(c) ? c : 0;
	if (typeof c === "string") {
		const n = Number(c);
		return Number.isFinite(n) ? n : 0;
	}
	const t = c?.total;
	if (typeof t === "number") return Number.isFinite(t) ? t : 0;
	if (typeof t === "string") {
		const n = Number(t);
		return Number.isFinite(n) ? n : 0;
	}
	return 0;
}

function sumSessionUsage(ctx: ExtensionCommandContext): {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	totalTokens: number;
	totalCost: number;
} {
	let input = 0;
	let output = 0;
	let cacheRead = 0;
	let cacheWrite = 0;
	let totalCost = 0;

	for (const entry of ctx.sessionManager.getEntries()) {
		if ((entry as any)?.type !== "message") continue;
		const msg = (entry as any)?.message;
		if (!msg || msg.role !== "assistant") continue;
		const usage = msg.usage;
		if (!usage) continue;
		input += Number(usage.inputTokens ?? 0) || 0;
		output += Number(usage.outputTokens ?? 0) || 0;
		cacheRead += Number(usage.cacheRead ?? 0) || 0;
		cacheWrite += Number(usage.cacheWrite ?? 0) || 0;
		totalCost += extractCostTotal(usage);
	}

	return {
		input,
		output,
		cacheRead,
		cacheWrite,
		totalTokens: input + output + cacheRead + cacheWrite,
		totalCost,
	};
}

function shortenPath(p: string, cwd: string): string {
	const rp = path.resolve(p);
	const rc = path.resolve(cwd);
	if (rp === rc) return ".";
	if (rp.startsWith(rc + path.sep)) return "./" + rp.slice(rc.length + 1);
	return rp;
}

function joinComma(items: string[]): string {
	return items.join(", ");
}

function padRight(s: string, w: number): string {
	return s.length >= w ? s : s + " ".repeat(w - s.length);
}

function padLeft(s: string, w: number): string {
	return s.length >= w ? s : " ".repeat(w - s.length) + s;
}

/** Compact token count: ~13.0k / ~239. */
function fmtTok(n: number): string {
	return n >= 1000 ? `~${(n / 1000).toFixed(1)}k` : `~${n}`;
}

type TokenRow = { name: string; tokens: number };

type ContextViewData = {
	header: {
		effective: number;
		contextWindow: number;
		percent: number;
		free: number;
		label: string;
	} | null;
	categories: ContextCategory[];
	tools: { total: number; perTool: TokenRow[] };
	skills: { total: number; perSkill: TokenRow[] };
	memoryFiles: string[];
	extensions: string[];
	loadedSkills: string[];
	session: { totalTokens: number; totalCost: number };
};

const SKILL_TABLE_CAP = 25;

class ContextView implements Component {
	private tui: TUI;
	private theme: any;
	private onDone: () => void;
	private data: ContextViewData;
	private container: Container;
	private body: Text;
	private cachedWidth?: number;

	constructor(tui: TUI, theme: any, data: ContextViewData, onDone: () => void) {
		this.tui = tui;
		this.theme = theme;
		this.data = data;
		this.onDone = onDone;

		this.container = new Container();
		this.container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
		this.container.addChild(
			new Text(
				theme.fg("accent", theme.bold("Context")) + theme.fg("dim", "  (Esc/q/Enter to close)"),
				1,
				0,
			),
		);
		this.container.addChild(new Text("", 1, 0));

		this.body = new Text("", 1, 0);
		this.container.addChild(this.body);

		this.container.addChild(new Text("", 1, 0));
		this.container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
	}

	private rebuild(width: number): void {
		const muted = (s: string) => this.theme.fg("muted", s);
		const dim = (s: string) => this.theme.fg("dim", s);
		const text = (s: string) => this.theme.fg("text", s);
		const accent = (s: string) => this.theme.fg("accent", s);
		const heading = (s: string) => this.theme.fg("accent", this.theme.bold(s));

		const lines: string[] = [];

		// Header: effective / window usage
		const h = this.data.header;
		if (!h) {
			lines.push(muted("Window: ") + dim("(unknown)"));
		} else {
			lines.push(
				text(`~${h.effective.toLocaleString()} / ${h.contextWindow.toLocaleString()} tokens`) +
					muted(`  (${h.percent.toFixed(1)}% used, ~${h.free.toLocaleString()} free)`),
			);
			lines.push(dim(`  ${h.label}`));
		}

		// Categories table (sorted desc; Free space last)
		lines.push("");
		lines.push(heading("By category"));
		const catLabelW = Math.max(...this.data.categories.map((c) => c.label.length), 8);
		const catTokW = Math.max(...this.data.categories.map((c) => fmtTok(c.tokens).length), 5);
		for (const c of this.data.categories) {
			const isFree = c.label === "Free space";
			const label = isFree ? dim(padRight(c.label, catLabelW)) : text(padRight(c.label, catLabelW));
			const tok = isFree ? dim(padLeft(fmtTok(c.tokens), catTokW)) : accent(padLeft(fmtTok(c.tokens), catTokW));
			lines.push(`  ${label}  ${tok}  ${dim(padLeft(`${c.pct.toFixed(1)}%`, 6))}`);
		}

		// Tools table (all active, sorted desc)
		lines.push("");
		lines.push(heading(`Tools (${this.data.tools.perTool.length} active, ${fmtTok(this.data.tools.total)})`));
		lines.push(...this.renderTokenRows(this.data.tools.perTool, this.data.tools.total, undefined));

		// Skills table (sorted desc, capped)
		const skills = this.data.skills.perSkill;
		lines.push("");
		lines.push(heading(`Skills (${skills.length}, ${fmtTok(this.data.skills.total)})`));
		const shown = skills.slice(0, SKILL_TABLE_CAP);
		const loaded = new Set(this.data.loadedSkills);
		lines.push(...this.renderTokenRows(shown, undefined, loaded));
		if (skills.length > shown.length) {
			const restTok = skills.slice(SKILL_TABLE_CAP).reduce((a, s) => a + s.tokens, 0);
			lines.push(dim(`  … +${skills.length - shown.length} more (${fmtTok(restTok)})`));
		}

		// Extensions + session
		lines.push("");
		lines.push(
			muted(`Extensions (${this.data.extensions.length}): `) +
				text(this.data.extensions.length ? joinComma(this.data.extensions) : "(none)"),
		);
		if (this.data.memoryFiles.length) {
			lines.push(muted(`Memory (${this.data.memoryFiles.length}): `) + text(joinComma(this.data.memoryFiles)));
		}
		lines.push(
			muted("Session: ") +
				text(`${this.data.session.totalTokens.toLocaleString()} tokens`) +
				muted(" · ") +
				text(formatUsd(this.data.session.totalCost)),
		);

		this.body.setText(lines.join("\n"));
		this.cachedWidth = width;
	}

	/** Aligned `  name   ~tok  pct%` rows. Loaded skills highlighted; pct omitted when total is undefined. */
	private renderTokenRows(rows: TokenRow[], total: number | undefined, loaded: Set<string> | undefined): string[] {
		const muted = (s: string) => this.theme.fg("muted", s);
		const dim = (s: string) => this.theme.fg("dim", s);
		const text = (s: string) => this.theme.fg("text", s);
		const accent = (s: string) => this.theme.fg("accent", s);
		const success = (s: string) => this.theme.fg("success", s);
		if (rows.length === 0) return [muted("  (none)")];
		const nameW = Math.min(34, Math.max(...rows.map((r) => r.name.length), 4));
		const tokW = Math.max(...rows.map((r) => fmtTok(r.tokens).length), 5);
		return rows.map((r) => {
			const name = r.name.length > nameW ? r.name.slice(0, nameW - 1) + "…" : r.name;
			const isLoaded = loaded?.has(r.name);
			const nameStr = (isLoaded ? success : text)(padRight(name, nameW));
			const tokStr = accent(padLeft(fmtTok(r.tokens), tokW));
			if (total && total > 0) {
				const pct = `${((r.tokens / total) * 100).toFixed(1)}%`;
				return `  ${nameStr}  ${tokStr}  ${dim(padLeft(pct, 6))}`;
			}
			return `  ${nameStr}  ${tokStr}`;
		});
	}

	handleInput(data: string): void {
		if (
			matchesKey(data, Key.escape) ||
			matchesKey(data, Key.ctrl("c")) ||
			data.toLowerCase() === "q" ||
			data === "\r"
		) {
			this.onDone();
			return;
		}
	}

	invalidate(): void {
		this.container.invalidate();
		this.cachedWidth = undefined;
	}

	render(width: number): string[] {
		if (this.cachedWidth !== width) this.rebuild(width);
		return this.container.render(width);
	}
}

export default function contextExtension(pi: ExtensionAPI) {
	// Track which skills were actually pulled in via read tool calls.
	let lastSessionId: string | null = null;
	let cachedLoadedSkills = new Set<string>();
	let cachedSkillIndex: SkillIndexEntry[] = [];

	const ensureCaches = (ctx: ExtensionContext) => {
		const sid = ctx.sessionManager.getSessionId();
		if (sid !== lastSessionId) {
			lastSessionId = sid;
			cachedLoadedSkills = getLoadedSkillsFromSession(ctx);
			cachedSkillIndex = buildSkillIndex(pi, ctx.cwd);
		}
		if (cachedSkillIndex.length === 0) {
			cachedSkillIndex = buildSkillIndex(pi, ctx.cwd);
		}
	};

	const matchSkillForPath = (absPath: string): string | null => {
		let best: SkillIndexEntry | null = null;
		for (const s of cachedSkillIndex) {
			if (!s.skillDir) continue;
			if (absPath === s.skillFilePath || absPath.startsWith(s.skillDir + path.sep)) {
				if (!best || s.skillDir.length > best.skillDir.length) best = s;
			}
		}
		return best?.name ?? null;
	};

	pi.on("tool_result", (event: ToolResultEvent, ctx: ExtensionContext) => {
		// Only count successful reads.
		if ((event as any).toolName !== "read") return;
		if ((event as any).isError) return;

		const input = (event as any).input as { path?: unknown } | undefined;
		const p = typeof input?.path === "string" ? input.path : "";
		if (!p) return;

		ensureCaches(ctx);
		const abs = normalizeReadPath(p, ctx.cwd);
		const skillName = matchSkillForPath(abs);
		if (!skillName) return;

		if (!cachedLoadedSkills.has(skillName)) {
			cachedLoadedSkills.add(skillName);
			pi.appendEntry<SkillLoadedEntryData>(SKILL_LOADED_ENTRY, { name: skillName, path: abs });
		}
	});

	pi.registerCommand("context", {
		description: "Show loaded context overview",
		handler: async (_args, ctx: ExtensionCommandContext) => {
			const commands = pi.getCommands();
			const extensionCmds = commands.filter((c) => c.source === "extension");

			const extensionsByPath = new Map<string, string[]>();
			for (const c of extensionCmds) {
				const p = c.sourceInfo?.path ?? "<unknown>";
				const arr = extensionsByPath.get(p) ?? [];
				arr.push(c.name);
				extensionsByPath.set(p, arr);
			}
			const extensionFiles = [...extensionsByPath.keys()]
				.map((p) => (p === "<unknown>" ? p : path.basename(p)))
				.sort((a, b) => a.localeCompare(b));

			const agentFiles = await loadProjectContextFiles(ctx.cwd);
			const memoryFiles = agentFiles.map((f) => shortenPath(f.path, ctx.cwd));

			// Slice the assembled system prompt into system / memory / skills regions, then
			// reconcile every category against the context window. Tools are computed from real
			// per-tool JSON schemas and sit on top of getContextUsage() (which excludes them).
			const systemPrompt = ctx.getSystemPrompt() ?? "";
			const regions = sliceSystemPrompt(systemPrompt);
			const systemTok = estimateTokens(regions.system);
			const memoryTok = estimateTokens(regions.memory);
			const skillsTok = estimateTokens(regions.skills);

			const usage = ctx.getContextUsage();
			const realTotal = usage?.tokens ?? null; // null when unknown (fresh / post-compaction)
			const ctxWindow = usage?.contextWindow ?? 0;

			const activeToolNames = pi.getActiveTools();
			const toolAgg = sumToolTokens(pi.getAllTools(), activeToolNames);
			const skillAgg = skillBreakdown(regions.skills);
			const messagesTok = estimateMessagesTokens(ctx.sessionManager.getEntries() as any[]);

			// Provider gives an exact total but no category split; char/4 gives the proportions.
			// Scale the char/4 categories to the real total so slices sum to it (model-agnostic).
			// Fresh sessions (no usage) reuse this model's last cached scale.
			const modelId = ctx.model?.id ?? "";
			const scaleCache = readScaleCacheFile();
			const cachedScale = modelId ? (scaleCache[modelId] ?? null) : null;

			const breakdown = buildScaledBreakdown({
				systemTok,
				memoryTok,
				skillsTok,
				toolsTok: toolAgg.total,
				messagesTok,
				realTotal,
				cachedScale,
				contextWindow: ctxWindow,
			});

			// Persist the freshly observed scale for this model (stable ~1.55 on Anthropic, ~1.05 on OpenAI).
			if (modelId && breakdown.scaleSource === "usage" && Number.isFinite(breakdown.scale) && breakdown.scale > 0) {
				scaleCache[modelId] = Number(breakdown.scale.toFixed(4));
				writeScaleCacheFile(scaleCache);
			}

			const headerTotal = breakdown.scaleSource === "usage" && realTotal ? realTotal : breakdown.effective;
			const headerFree = ctxWindow > 0 ? Math.max(0, ctxWindow - headerTotal) : 0;
			const percent = ctxWindow > 0 ? (headerTotal / ctxWindow) * 100 : 0;
			const totalLabel = scaleLabel(breakdown.scaleSource, breakdown.scale);

			const sessionUsage = sumSessionUsage(ctx);
			const loadedSkills = Array.from(getLoadedSkillsFromSession(ctx)).sort((a, b) => a.localeCompare(b));

			const makePlainText = () => {
				const lines: string[] = [];
				if (ctxWindow > 0) {
					lines.push(
						`Context  ~${headerTotal.toLocaleString()} / ${ctxWindow.toLocaleString()} tokens (${percent.toFixed(1)}% used, ~${headerFree.toLocaleString()} free)  [${totalLabel}]`,
					);
				} else {
					lines.push("Context  (window unknown)");
				}

				lines.push("");
				lines.push("By category:");
				for (const c of breakdown.categories) {
					lines.push(`  ${padRight(c.label, 14)}  ${padLeft(fmtTok(c.tokens), 8)}  ${padLeft(`${c.pct.toFixed(1)}%`, 6)}`);
				}

				lines.push("");
				lines.push(`Tools (${toolAgg.perTool.length} active, ${fmtTok(toolAgg.total)}):`);
				const toolNameW = Math.min(34, Math.max(...toolAgg.perTool.map((t) => t.name.length), 4));
				for (const t of toolAgg.perTool) {
					const pct = toolAgg.total > 0 ? `${((t.tokens / toolAgg.total) * 100).toFixed(1)}%` : "";
					lines.push(`  ${padRight(t.name, toolNameW)}  ${padLeft(fmtTok(t.tokens), 8)}  ${padLeft(pct, 6)}`);
				}

				lines.push("");
				lines.push(`Skills (${skillAgg.perSkill.length}, ${fmtTok(skillAgg.total)}):`);
				const skillNameW = Math.min(40, Math.max(...skillAgg.perSkill.map((s) => s.name.length), 4));
				for (const s of skillAgg.perSkill) {
					lines.push(`  ${padRight(s.name, skillNameW)}  ${padLeft(fmtTok(s.tokens), 8)}`);
				}

				lines.push("");
				lines.push(`Extensions (${extensionFiles.length}): ${extensionFiles.length ? joinComma(extensionFiles) : "(none)"}`);
				if (memoryFiles.length) lines.push(`Memory (${memoryFiles.length}): ${joinComma(memoryFiles)}`);
				lines.push(`Session: ${sessionUsage.totalTokens.toLocaleString()} tokens · ${formatUsd(sessionUsage.totalCost)}`);
				return lines.join("\n");
			};

			if (!ctx.hasUI) {
				pi.sendMessage({ customType: "context", content: makePlainText(), display: true }, { triggerTurn: false });
				return;
			}

			const viewData: ContextViewData = {
				header: ctxWindow > 0
					? { effective: headerTotal, contextWindow: ctxWindow, percent, free: headerFree, label: totalLabel }
					: null,
				categories: breakdown.categories,
				tools: toolAgg,
				skills: { total: skillAgg.total, perSkill: skillAgg.perSkill },
				memoryFiles,
				extensions: extensionFiles,
				loadedSkills,
				session: { totalTokens: sessionUsage.totalTokens, totalCost: sessionUsage.totalCost },
			};

			await ctx.ui.custom<void>((tui, theme, _kb, done) => {
				return new ContextView(tui, theme, viewData, done);
			});
		},
	});
}
