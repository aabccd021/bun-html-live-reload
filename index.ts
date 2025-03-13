declare global {
  var clients: Set<ReadableStreamDefaultController> | undefined;
  var autoReload: boolean | undefined;
}

globalThis.clients ??= new Set<ReadableStreamDefaultController>();
globalThis.autoReload = globalThis.autoReload ?? true;

export function reloadClients(): void {
  if (globalThis.clients !== undefined) {
    for (const client of globalThis.clients) {
      client.enqueue("data: RELOAD\n\n");
    }
  }
}

if (globalThis.autoReload) {
  reloadClients();
}

export type LiveReloadOptions = {
  /**
   * URL path used for server-sent events
   * @default "__dev__/reload"
   */
  readonly eventPath?: string;

  /**
   * URL path used for live reload script
   * @default "__dev__/ws"
   */
  readonly scriptPath?: string;
};

type Fetch = (req: Request) => Promise<Response>;

/**
 * Automatically reload html when Bun server hot reloads
 *
 * @param fetch Bun server's fetch function
 * @param options Live reload options
 *
 * @returns fetch function with live reload
 */
export function withHtmlLiveReload(
  handler: Fetch,
  options?: {
    eventPath?: string;
    scriptPath?: string;
    autoReload?: false;
  },
): Fetch {
  if (options?.autoReload === false) {
    globalThis.autoReload = false;
  }
  return async (req): Promise<Response> => {
    if (req.method !== "GET") {
      return handler(req);
    }

    const requestUrl = new URL(req.url);

    const { eventPath, scriptPath } = {
      eventPath: "/__dev__/reload",
      scriptPath: "/__dev__/reload.js",
      ...options,
    };

    if (requestUrl.pathname === eventPath) {
      const stream = new ReadableStream({
        start(controller): void {
          globalThis.clients?.add(controller);
          req.signal.addEventListener("abort", () => {
            controller.close();
            globalThis.clients?.delete(controller);
          });
        },
      });

      return new Response(stream, {
        headers: {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
        },
      });
    }

    if (requestUrl.pathname === scriptPath) {
      return new Response(
        `new EventSource("${eventPath}").onmessage = function(msg) {  
          if(msg.data === 'RELOAD') { location.reload(); }
         };`,
        { headers: { "Content-Type": "text/javascript" } },
      );
    }

    const response = await handler(req);

    const contentType = response.headers.get("Content-Type");
    const isResponseHtml = contentType?.startsWith("text/html") ?? false;
    if (!isResponseHtml) {
      return response;
    }

    const liveReloadScript = `<script type="module" src="${scriptPath}"></script>`;

    return new HTMLRewriter()
      .onDocument({
        end: (el): void => {
          el.append(liveReloadScript, { html: true });
        },
      })
      .transform(response);
  };
}
