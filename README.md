# bun-html-live-reload

HTML live reload for Bun

## Getting Started

```sh
bun add -d bun-html-live-reload
```

```ts
// example.ts
import { withHtmlLiveReload } from "bun-html-live-reload";

Bun.serve({
  fetch: withHtmlLiveReload(async (request) => {
    return new Response("<div>hello world</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }),
});
```

- Run the server with `bun --hot example.ts`, open browser, and try to edit the `hello world` part.
- The page should live reload as you edit!
- This plugin relies on response header to identify html response,
  so don't forget to add `"Content-Type": "text/html"` header to your `Response`.

## Options

You can specify URL paths used for server-sent events and live reloader script.

```ts
Bun.serve({
  fetch: withHtmlLiveReload(
    async (request) => {
      /* ... */
    },
    {
      // SSE Path
      // default: "/__dev__/reload"
      eventPath: "/__reload",

      // Live reload script path
      // default: "/__dev__/reload.js"
      scriptPath: "/__reload.js",

      // Wether to enable auto reload.
      // If false, you need to manually call `reloadClients` function to reload clients.
      // default: true
      autoReload: false,
    },
  ),
});
```

## Manually reload clients

You can manually reload clients (refresh tabs) by calling `reloadClients` function,
in addition to auto reload feature.

```ts
import { withHtmlLiveReload, reloadClients } from "bun-html-live-reload";

Bun.serve({
  fetch: withHtmlLiveReload(async (request) => {
    /* ... */
  }),
});

// reload clients every second
setInterval(() => {
  reloadClients();
}, 1000);
```

# Changes from v0.1

- Messages are sent through SSE (HTTP streaming) instead of Websocket.
- Wraps only `fetch` function instead of the whole server.
- Exposes `reloadClients` function to manually reload clients.
- Uses separate javascript file instead of inline script to comply with strict CSP.
- Supports multiple clients (tabs).
- Added tests

# Migration from v0.1

## v0.1

```ts
import { withHtmlLiveReload } from "bun-html-live-reload";
import { $ } from "bun";

export default Bun.serve(
  withHtmlLiveReload(
    {
      fetch: (request) => {
        /* ... */
      },
    },
    {
      watchPath: path.resolve(import.meta.dir, "src"),
      buildConfig: {
        entrypoints: ["./src/index.tsx"],
        outdir: "./build",
      },
      onChange: async () => {
        await $`rm -r ./dist`;
      },
    },
  ),
);
```

## v1.0

```ts
import { withHtmlLiveReload, reloadClients } from "bun-html-live-reload";
import { FSWatcher, watch } from "fs";
import { $ } from "bun";

const buildConfig = {
  entrypoints: ["./src/index.tsx"],
  outdir: "./build",
};

Bun.build(buildConfig);

watch(path.resolve(import.meta.url, "src")).on("change", async () => {
  await $`rm -r ./dist`;
  await Bun.build(buildConfig);
  reloadClients();
});

Bun.serve({
  fetch: withHtmlLiveReload(async (request) => {
    /* ... */
  }),
});
```
