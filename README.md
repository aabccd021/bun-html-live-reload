# bun-html-live-reload

HTML live reload for Bun

## Getting Started

```ts
// example.ts
import { withHtmlLiveReload } from "bun-html-live-reload";

export default withHtmlLiveReload({
  fetch: () => {
    return new Response("<div>hello world</div>", {
      headers: { "Content-Type": "text/html" },
    });
  },
});
```

- Wrap your regular [hot reloading Bun server](https://bun.sh/docs/runtime/hot#http-servers) with `withHtmlLiveReload`.
- Run the server with `bun --hot example.ts`, open browser, and try to edit the `hello world` part.
- The page should live reload as you edit!

## Response Header

This plugin relies on response header to identify html file,
so don't forget to add `{ headers: { "Content-Type": "text/html" }, }` to your `Response`.

## Installation

```sh
bun add --development github:aabccd021/bun-html-live-reload
```

## Options

### `wsPath`

URL path used for websocket connection.

This library relies on websocket to live reload an HTML.
The path `wsPath` will be used to upgrade HTTP connection to websocket one.

For example, the default `wsPath` value `__bun_live_reload_websocket__`,
will upgrade `http://localhost:3000/__bun_live_reload_websocket__`
to `ws://localhost:3000/__bun_live_reload_websocket__`.

```ts
export default withHtmlLiveReload(
  {
    fetch: () => {
      return new Response("<div>hello world</div>", {
        headers: { "Content-Type": "text/html" },
      });
    },
  },
  {
    wsPath: "your_ws_path",
  }
);
```

### React HMR: `watchPath` and `buildConfig`

The `watchPath` is the file or folder path that should be watched to trigger the reloads. This could be used to reload html files on changing files in other folders like `src` for react projects.

The `buildConfig` is used for running the `Bun.build()` command when the files in the `watchPath` change. The `Bun.build()` command will always be run once before starting the server.

```ts
export default withHtmlLiveReload(
  {
    ...
  },
  {
    watchPath: path.resolve(import.meta.dir, "src"),
    buildConfig: {
      entrypoints: ["./src/index.tsx"],
      outdir: "./build"
    }
  }
);
```
