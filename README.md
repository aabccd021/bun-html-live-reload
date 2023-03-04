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

