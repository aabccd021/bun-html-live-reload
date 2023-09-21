import type {
  Server,
  ServerWebSocket,
  WebSocketHandler,
  WebSocketServeOptions,
  BuildConfig,
} from "bun";
import { FSWatcher, watch } from "fs";

declare global {
  var ws: ServerWebSocket<unknown> | undefined;
}

const reloadCommand = "reload";

globalThis.ws?.send(reloadCommand);

const makeLiveReloadScript = (wsUrl: string) => `
<!-- start bun live reload script -->
<script type="text/javascript">
  (function() {
    const socket = new WebSocket("ws://${wsUrl}");
      socket.onmessage = function(msg) {
      if(msg.data === '${reloadCommand}') {
        location.reload()
      }
    };
    console.log('Live reload enabled.');
  })();
</script>
<!-- end bun live reload script -->
`;

export type PureWebSocketServeOptions<WebSocketDataType> = Omit<
  WebSocketServeOptions<WebSocketDataType>,
  "fetch" | "websocket"
> & {
  fetch(request: Request, server: Server): Promise<Response> | Response;
  websocket?: WebSocketHandler<WebSocketDataType>;
};

export type LiveReloadOptions = {
  /**
   * URL path used for websocket connection
   * @default "__bun_live_reload_websocket__"
   */
  readonly wsPath?: string;
  readonly buildConfig?: BuildConfig;
  readonly watchPath?: string;
};

/**
 * Automatically reload html when Bun server hot reloads
 *
 * @param serverOptions Bun's server options
 * @param options Live reload options
 *
 * @returns Bun's server with provided options that live reloads HTML
 *
 * @example
 *```ts
 *import { withHtmlLiveReload } from "bun-html-live-reload";
 *
 *export default withHtmlLiveReload({
 *  fetch: () => {
 *    return new Response("<div>hello world</div>", {
 *      headers: { "Content-Type": "text/html" },
 *    });
 *  },
 *});
 */
export const withHtmlLiveReload = <
  WebSocketDataType,
  T extends PureWebSocketServeOptions<WebSocketDataType>
>(
  serveOptions: T,
  options?: LiveReloadOptions
): WebSocketServeOptions<WebSocketDataType> => {
  const port = serveOptions.port ?? "3000";
  const wsPath = options?.wsPath ?? "__bun_live_reload_websocket__";
  const wsUrl = (hostname: string) => `${hostname}:${port}/${wsPath}`;

  const { buildConfig, watchPath } = options ?? {};
  if (buildConfig) Bun.build(buildConfig);
  let watcher: FSWatcher;
  if (watchPath) watcher = watch(watchPath);

  return {
    ...serveOptions,
    fetch: async (req, server) => {
      if (req.url === `http://${wsUrl(server.hostname)}`) {
        const upgraded = server.upgrade(req);

        if (!upgraded) {
          return new Response(
            "Failed to upgrade websocket connection for live reload",
            { status: 400 }
          );
        }
        return;
      }

      const response = await serveOptions.fetch(req, server);

      if (!response.headers.get("Content-Type")?.startsWith("text/html")) {
        return response;
      }

      const originalHtml = await response.text();
      const liveReloadScript = makeLiveReloadScript(wsUrl(server.hostname));
      const htmlWithLiveReload = originalHtml + liveReloadScript;

      return new Response(htmlWithLiveReload, response);
    },
    websocket: {
      ...serveOptions.websocket,
      open: async (ws) => {
        globalThis.ws = ws;
        await serveOptions.websocket?.open?.(ws);

        if (watcher)
          watcher.on("change", async () => {
            if (buildConfig) await Bun.build(buildConfig);
            ws.send(reloadCommand);
          });
      },
    },
  };
};
