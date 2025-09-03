import { chromium } from "playwright";

const serverCodeInitial = `
import { withHtmlLiveReload, reload } from "./index.ts";

Bun.serve({
  port: 3000,
  fetch: withHtmlLiveReload(async () => {
    return new Response("<div>Init</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }),
});

reload();
`;

const serverCodeChanged = `
import { withHtmlLiveReload, reload } from "./index.ts";

Bun.serve({
  port: 3000,
  fetch: withHtmlLiveReload(async () => {
    return new Response("<div>Changed</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }),
});

reload();
`;

await Bun.write("server.ts", serverCodeInitial);

const serverProcess = Bun.spawn(["bun", "--hot", "server.ts"]);

const browser = await chromium.launch();

const context = await browser.newContext();
const page = await context.newPage();
await page.goto("http://localhost:3000");

if ((await page.locator("div").textContent()) !== "Init") throw new Error();

await Bun.write("server.ts", serverCodeChanged);
await page.waitForEvent("framenavigated");

if ((await page.locator("div").textContent()) !== "Changed") throw new Error();

await browser.close();
serverProcess.kill();
