import { expect, test } from "bun:test";
import * as fs from "node:fs";
import { chromium } from "playwright";

const serverCodeInit = `
import { withHtmlLiveReload } from "./bun-html-live-reload.ts";

Bun.serve({
  fetch: withHtmlLiveReload(async () => {
    return new Response("<div>Init</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }),
});
`;

const serverCodeChanged = `
import { withHtmlLiveReload } from "./bun-html-live-reload.ts";
Bun.serve({
  fetch: withHtmlLiveReload(async () => {
    return new Response("<div>Changed</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }),
});
`;

test("hot reload works", async () => {
  const systemTmp = process.env.TMPDIR ?? "/tmp";
  const tmpdir = fs.mkdtempSync(`${systemTmp}/bun-`);
  const serverPath = `${tmpdir}/server.ts`;

  await Bun.write(serverPath, serverCodeInit);

  fs.copyFileSync(`${import.meta.dir}/../index.ts`, `${tmpdir}/bun-html-live-reload.ts`);

  Bun.spawn(["bun", "--hot", serverPath], { stderr: "ignore" });

  const browser = await chromium.launch({});

  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto("http://localhost:3000");

  expect(await page.locator("div").textContent()).toBe("Init");

  await Bun.write(serverPath, serverCodeChanged);
  await page.waitForEvent("framenavigated");

  expect(await page.locator("div").textContent()).toBe("Changed");
});
