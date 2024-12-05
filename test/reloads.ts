import { chromium } from "playwright";
import * as fs from "fs";

const systemTmp = process.env["TMPDIR"] ?? "/tmp";
const tmpdir = fs.mkdtempSync(`${systemTmp}/bun-`);

fs.copyFileSync(`${import.meta.dir}/../example.ts`, `${tmpdir}/example.ts`);
fs.copyFileSync(`${import.meta.dir}/../index.ts`, `${tmpdir}/index.ts`);

const child = Bun.spawn(["bun", "--hot", `${tmpdir}/example.ts`], {
  stderr: "ignore",
});

process.on("exit", async () => {
  child?.kill();
  await browser.close();
});

const browser = await chromium.launch();

const context = await browser.newContext();
const page = await context.newPage();
await page.goto("http://localhost:3000");

const name = await page.innerText("div");
if (name !== "Init") {
  throw new Error(`Unexpected content ${name}`);
}

const text = await Bun.file(`${tmpdir}/example.ts`).text();
const newText = text.replace("Init", "Changed");
await Bun.write(`${tmpdir}/example.ts`, newText);

await page.waitForEvent("framenavigated");

const newName = await page.innerText("div");
if (newName !== "Changed") {
  throw new Error(`Unexpected content: ${newName}`);
}

process.exit(0);
