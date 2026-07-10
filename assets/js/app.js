import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();
window.liveSocket = liveSocket;

const themeStorageKey = "incant-theme";
const shell = () => document.querySelector("[data-incant-shell]");

function preferredTheme() {
  const stored = window.localStorage.getItem(themeStorageKey);
  if (stored === "dark" || stored === "light") return stored;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function applyTheme(theme) {
  const dark = theme === "dark";
  document.documentElement.classList.toggle("dark", dark);
  document.querySelectorAll("[data-incant-theme-icon='sun']").forEach((icon) => icon.classList.toggle("hidden", dark));
  document.querySelectorAll("[data-incant-theme-icon='moon']").forEach((icon) => icon.classList.toggle("hidden", !dark));
}

function closeNavigation() {
  shell()?.classList.remove("incant-nav-open");
  document.querySelectorAll("[data-incant-nav-toggle]").forEach((button) => button.setAttribute("aria-expanded", "false"));
}

function toggleNavigation() {
  const isOpen = shell()?.classList.toggle("incant-nav-open");
  document.querySelectorAll("[data-incant-nav-toggle]").forEach((button) => button.setAttribute("aria-expanded", String(Boolean(isOpen))));
}

function scheduleFlashDismissal() {
  document.querySelectorAll("[data-incant-flash]").forEach((flash) => {
    if (flash.dataset.incantFlashScheduled) return;

    flash.dataset.incantFlashScheduled = "true";
    window.setTimeout(() => flash.querySelector("[data-incant-flash-close]")?.click(), 5000);
  });
}

applyTheme(preferredTheme());
scheduleFlashDismissal();
new MutationObserver(scheduleFlashDismissal).observe(document.body, { childList: true, subtree: true });

document.addEventListener("click", (event) => {
  if (event.target.closest("[data-incant-theme-toggle]")) {
    const theme = document.documentElement.classList.contains("dark") ? "light" : "dark";
    window.localStorage.setItem(themeStorageKey, theme);
    applyTheme(theme);
  }

  if (event.target.closest("[data-incant-nav-toggle]")) toggleNavigation();
  if (event.target.closest("[data-incant-nav-backdrop]")) closeNavigation();
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") closeNavigation();
});
