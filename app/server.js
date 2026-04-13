const fs = require("fs");
const os = require("os");
const path = require("path");
const express = require("express");

const app = express();
const port = Number(process.env.PORT || 80);
const appName = process.env.APP_NAME || "observable-demo-app";
const appEnv = process.env.APP_ENV || "dev";
const appVersion = process.env.APP_VERSION || "1.0.0";
const htmlTemplate = fs.readFileSync(path.join(__dirname, "public", "index.html"), "utf8");

function sleep(delayMs) {
  return new Promise((resolve) => setTimeout(resolve, delayMs));
}

function buildRequestId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

function logEvent(level, message, fields = {}) {
  console.log(
    JSON.stringify({
      timestamp: new Date().toISOString(),
      level,
      message,
      appName,
      appEnv,
      appVersion,
      hostname: os.hostname(),
      ...fields,
    })
  );
}

function getRequestId(req) {
  return req.headers["x-request-id"] || buildRequestId();
}

function renderHomePage() {
  return htmlTemplate
    .replace(/__APP_NAME__/g, appName)
    .replace(/__APP_ENV__/g, appEnv)
    .replace(/__APP_VERSION__/g, appVersion)
    .replace(/__HOSTNAME__/g, os.hostname())
    .replace(/__TIMESTAMP__/g, new Date().toISOString());
}

app.use((req, res, next) => {
  req.requestId = getRequestId(req);
  res.setHeader("x-request-id", req.requestId);

  logEvent("INFO", "request received", {
    route: req.path,
    method: req.method,
    requestId: req.requestId,
    query: req.query,
  });

  next();
});

app.get("/", (req, res) => {
  res.status(200).type("html").send(renderHomePage());
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    appName,
    appEnv,
    appVersion,
    hostname: os.hostname(),
    requestId: req.requestId,
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/demo", (req, res) => {
  res.status(200).json({
    message: "demo response",
    appName,
    appEnv,
    appVersion,
    hostname: os.hostname(),
    requestId: req.requestId,
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/slow", async (req, res) => {
  const requestedDelay = Number(req.query.delay || 2000);
  const delayMs = Math.max(0, Math.min(requestedDelay, 15000));

  await sleep(delayMs);

  logEvent("WARN", "slow request served", {
    route: req.path,
    requestId: req.requestId,
    delayMs,
  });

  res.status(200).json({
    message: "slow response",
    delayMs,
    requestId: req.requestId,
    appName,
    appEnv,
    appVersion,
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/error", (req, res) => {
  const requestedCode = Number(req.query.code || 500);
  const statusCode = requestedCode >= 400 && requestedCode <= 599 ? requestedCode : 500;

  logEvent("ERROR", "intentional error response", {
    route: req.path,
    requestId: req.requestId,
    statusCode,
  });

  res.status(statusCode).json({
    message: "intentional error for monitoring demo",
    statusCode,
    requestId: req.requestId,
    appName,
    appEnv,
    appVersion,
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/log-demo", (req, res) => {
  logEvent("INFO", "structured log demo", {
    route: req.path,
    requestId: req.requestId,
    sampleUserId: "demo-user-123",
  });

  res.status(200).json({
    message: "structured log emitted",
    requestId: req.requestId,
    appName,
    appEnv,
    appVersion,
    timestamp: new Date().toISOString(),
  });
});

app.listen(port, () => {
  logEvent("INFO", "application started", { port });
});