import type { SourceAttachment, SourceObserver } from "./contract.ts";
import {
  kakaoIdentity,
  readBoundedText,
  SOURCE_TIMEOUT_MS,
  trustedSourceUrl,
} from "./security.ts";

function decode(value: string): string {
  return value.replace(
    /&(#x[0-9a-f]+|#[0-9]+|amp|quot|apos|lt|gt|nbsp);/gi,
    (_, code: string) => {
      if (code.startsWith("#")) {
        const n = code[1].toLowerCase() === "x"
          ? parseInt(code.slice(2), 16)
          : Number(code.slice(1));
        return n > 0 && n <= 0x10ffff ? String.fromCodePoint(n) : "";
      }
      return ({
        amp: "&",
        quot: '"',
        apos: "'",
        lt: "<",
        gt: ">",
        nbsp: " ",
      } as Record<string, string>)[code.toLowerCase()];
    },
  );
}
// Narrow fail-closed Tistory attachment reader, not a port of ingestion taxonomy.
// Raw script/style/comments are removed; only anchors inside an article div count.
export function observeHtml(
  html: string,
): { attachments: SourceAttachment[] } | null {
  const body = html.replace(/<!--[\s\S]*?-->/g, "").replace(
    /<(script|style|textarea|template)\b[^>]*>[\s\S]*?<\/\1\s*>/gi,
    "",
  );
  if (/<!--|<(script|style|textarea|template)\b/i.test(body)) return null;
  const tokens = body.match(/<[^>]*>|[^<]+/g) ?? [];
  const stack: { tag: string; article: boolean }[] = [];
  const attachments: SourceAttachment[] = [];
  let anchor: { href: string; text: string; mime?: string } | null = null;
  let seen = false;
  for (const token of tokens) {
    if (!token.startsWith("<")) {
      if (anchor) anchor.text += decode(token);
      continue;
    }
    const close = /^<\/([a-z0-9]+)\s*>$/i.exec(token);
    if (close) {
      const tag = close[1].toLowerCase();
      if (tag === "a" && anchor) {
        const key = kakaoIdentity(anchor.href);
        if (key) {
          attachments.push({
            provider: "kakaocdn",
            sourceResourceKey: key,
            currentTarget: anchor.href,
            mimeType: anchor.mime,
            fileExtension: /\.pdf(?:\s|$)/i.test(anchor.text.trim())
              ? "pdf"
              : null,
          });
        }
        anchor = null;
      }
      if (anchor) anchor.text += " ";
      const at = stack.map((x) => x.tag).lastIndexOf(tag);
      if (at >= 0) stack.length = at;
      continue;
    }
    const open = /^<([a-z0-9]+)\b([\s\S]*?)\/?\s*>$/i.exec(token);
    if (!open) continue;
    const tag = open[1].toLowerCase();
    const attrs: Record<string, string> = {};
    const attrRe =
      /([a-z_:][a-z0-9_:.-]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))/gi;
    for (const m of open[2].matchAll(attrRe)) {
      const k = m[1].toLowerCase();
      if (k in attrs) return null;
      attrs[k] = decode(m[2] ?? m[3] ?? m[4]);
    }
    const article = stack.some((x) => x.article) || tag === "div" &&
        /(?:^|\s)(?:contents_style|tt_article_useless_p_margin)(?:\s|$)/.test(
          attrs.class ?? "",
        );
    if (article) seen = true;
    if (tag === "a" && article) {
      if (anchor) return null;
      anchor = { href: attrs.href ?? "", text: "", mime: attrs.type };
    }
    if (
      !/^(area|base|br|col|embed|hr|img|input|link|meta|param|source|track|wbr)$/
        .test(tag) && !token.endsWith("/>")
    ) stack.push({ tag, article });
    if (stack.length > 128 || attachments.length > 1000) return null;
  }
  return seen && !anchor ? { attachments } : null;
}

export function createBoundedSourceObserver(
  fetcher: typeof fetch = fetch,
  timeoutMs = SOURCE_TIMEOUT_MS,
): SourceObserver {
  if (timeoutMs < 1 || timeoutMs > SOURCE_TIMEOUT_MS) {
    throw new Error("invalid deadline");
  }
  return {
    async observe(sourceUrl: string) {
      const target = trustedSourceUrl(sourceUrl);
      if (!target) return null;
      const abort = new AbortController();
      let response: Response | undefined;
      let timer: ReturnType<typeof setTimeout> | undefined;
      const work = async () => {
        response = await fetcher(target, {
          method: "GET",
          redirect: "manual",
          signal: abort.signal,
          headers: { Accept: "text/html", "Accept-Encoding": "identity" },
        });
        if (abort.signal.aborted) {
          await response.body?.cancel();
          return null;
        }
        if (
          response.status !== 200 ||
          !/^(text\/html|application\/xhtml\+xml)(;|$)/i.test(
            response.headers.get("content-type") ?? "",
          )
        ) {
          await response.body?.cancel();
          return null;
        }
        // Fetch runtime must decode Content-Encoding; reader enforces actual decoded bytes.
        const html = await readBoundedText(response, undefined, abort.signal);
        return html === null ? null : observeHtml(html);
      };
      try {
        return await Promise.race([
          work(),
          new Promise<null>((resolve) => {
            timer = setTimeout(() => {
              abort.abort();
              resolve(null);
            }, timeoutMs);
          }),
        ]);
      } catch {
        return null;
      } finally {
        if (timer) clearTimeout(timer);
        abort.abort();
      }
    },
  };
}
