import "phoenix_html";
import type { LiveSocket } from "phoenix_live_view";
import { recentDateRange } from "./date_range";

type Theme = "dark" | "light";

interface CloseNavigationOptions {
  restoreFocus?: boolean;
}

declare global {
  interface Window {
    liveSocket: LiveSocket;
  }
}

export function mountIncant(): void {
  const themeStorageKey = "incant-theme";
  const mobileNavigation = window.matchMedia("(max-width: 1023px)");
  const shell = (): HTMLElement | null => document.querySelector<HTMLElement>("[data-incant-shell]");
  const sidebar = (): HTMLElement | null => document.querySelector<HTMLElement>("[data-incant-sidebar]");
  const navigationToggle = (): HTMLButtonElement | null =>
    document.querySelector<HTMLButtonElement>("[data-incant-nav-toggle]");

  function eventElement(event: Event): Element | null {
    return event.target instanceof Element ? event.target : null;
  }

  interface ConfirmPayload {
    title?: string;
    message?: string;
    confirm?: string;
    destructive?: boolean;
  }

  let confirmSource: HTMLElement | null = null;
  let confirmBypass = false;

  function confirmDialog(): HTMLDialogElement | null {
    return document.querySelector<HTMLDialogElement>("[data-incant-confirm-dialog]");
  }

  function confirmPart<T extends HTMLElement>(selector: string): T | null {
    return confirmDialog()?.querySelector<T>(selector) ?? null;
  }

  function openConfirmDialog(source: HTMLElement, payload: ConfirmPayload): void {
    const dialog = confirmDialog();
    if (!dialog?.showModal) return;

    const title = confirmPart("[data-incant-confirm-title]");
    const message = confirmPart("[data-incant-confirm-message]");
    const accept = confirmPart<HTMLButtonElement>("[data-incant-confirm-accept]");

    if (title) title.textContent = payload.title || "Are you sure?";
    if (message) {
      message.textContent = payload.message || "";
      message.classList.toggle("hidden", !payload.message);
    }
    if (accept) {
      accept.textContent = payload.confirm || "Confirm";
      const variantClass = payload.destructive ? accept.dataset.dangerClass : accept.dataset.primaryClass;
      if (variantClass) accept.className = variantClass;
    }

    confirmSource = source;
    wireDialogCancel(dialog, closeConfirmDialog);
    dialog.showModal();
    accept?.focus();
  }

  function closeConfirmDialog(): void {
    confirmDialog()?.close();
    confirmSource = null;
  }

  function wireDialogCancel(dialog: HTMLDialogElement | null, close: () => void): void {
    if (!dialog || dialog.dataset.incantCancelWired === "true") return;
    dialog.dataset.incantCancelWired = "true";
    dialog.addEventListener("cancel", (event) => {
      event.preventDefault();
      close();
    });
    dialog.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        event.preventDefault();
        event.stopPropagation();
        close();
      }
    });
  }

  function preferredTheme(): Theme {
    const stored = window.localStorage.getItem(themeStorageKey);
    if (stored === "dark" || stored === "light") return stored;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function applyTheme(theme: Theme): void {
    const dark = theme === "dark";
    document.documentElement.classList.toggle("dark", dark);
    document
      .querySelectorAll<HTMLElement>("[data-incant-theme-icon='sun']")
      .forEach((icon) => icon.classList.toggle("hidden", dark));
    document
      .querySelectorAll<HTMLElement>("[data-incant-theme-icon='moon']")
      .forEach((icon) => icon.classList.toggle("hidden", !dark));
  }

  function syncNavigation(open: boolean): void {
    const mobile = mobileNavigation.matches;
    const expanded = mobile && open;

    shell()?.classList.toggle("incant-nav-open", expanded);
    sidebar()?.toggleAttribute("inert", mobile && !expanded);
    sidebar()?.setAttribute("aria-hidden", String(mobile && !expanded));
    document
      .querySelectorAll<HTMLButtonElement>("[data-incant-nav-toggle]")
      .forEach((button) => button.setAttribute("aria-expanded", String(expanded)));
  }

  function closeNavigation({ restoreFocus = false }: CloseNavigationOptions = {}): void {
    syncNavigation(false);
    if (restoreFocus && mobileNavigation.matches) navigationToggle()?.focus();
  }

  function toggleNavigation(): void {
    const open = !shell()?.classList.contains("incant-nav-open");
    syncNavigation(open);

    if (open) {
      window.requestAnimationFrame(() => sidebar()?.querySelector<HTMLAnchorElement>("a")?.focus());
    }
  }

  function comboboxParts(root: HTMLElement): {
    input: HTMLInputElement | null;
    list: HTMLElement | null;
    options: HTMLButtonElement[];
    empty: HTMLElement | null;
  } {
    return {
      input: root.querySelector<HTMLInputElement>("[data-incant-combobox-input]"),
      list: root.querySelector<HTMLElement>("[data-incant-combobox-list]"),
      options: Array.from(root.querySelectorAll<HTMLButtonElement>("[data-incant-combobox-option]")),
      empty: root.querySelector<HTMLElement>("[data-incant-combobox-empty]"),
    };
  }

  function closeCombobox(root: HTMLElement): void {
    const { input, list, options } = comboboxParts(root);
    if (list) list.hidden = true;
    input?.setAttribute("aria-expanded", "false");
    input?.removeAttribute("aria-activedescendant");
    options.forEach((option) => option.setAttribute("aria-selected", "false"));
  }

  function closeOtherComboboxes(current?: HTMLElement): void {
    document.querySelectorAll<HTMLElement>("[data-incant-combobox]").forEach((root) => {
      if (root !== current) closeCombobox(root);
    });
  }

  function visibleComboboxOptions(root: HTMLElement): HTMLButtonElement[] {
    return comboboxParts(root).options.filter((option) => !option.hidden);
  }

  function activateComboboxOption(root: HTMLElement, index: number): void {
    const { input, options } = comboboxParts(root);
    const visible = visibleComboboxOptions(root);
    if (visible.length === 0) return;

    const option = visible[(index + visible.length) % visible.length];
    options.forEach((candidate) => candidate.setAttribute("aria-selected", String(candidate === option)));
    input?.setAttribute("aria-activedescendant", option.id);
    option.scrollIntoView({ block: "nearest" });
  }

  function openCombobox(root: HTMLElement): void {
    closeOtherComboboxes(root);
    const { input, list, options, empty } = comboboxParts(root);
    if (!input || !list) return;

    const query = input.value.trim().toLocaleLowerCase();
    let visibleCount = 0;

    options.forEach((option) => {
      const value = option.dataset.value || "";
      const matches =
        query === "" ||
        value.toLocaleLowerCase().includes(query) ||
        option.textContent?.trim().toLocaleLowerCase().includes(query);
      option.hidden = !matches;
      option.setAttribute("aria-selected", "false");
      if (matches) visibleCount += 1;
    });

    if (empty) empty.hidden = visibleCount > 0;
    list.hidden = false;
    input.setAttribute("aria-expanded", "true");
    input.removeAttribute("aria-activedescendant");
  }

  function chooseComboboxOption(root: HTMLElement, option: HTMLButtonElement): void {
    const { input } = comboboxParts(root);
    if (!input) return;
    input.value = option.dataset.value || option.textContent?.trim() || "";
    input.dispatchEvent(new Event("input", { bubbles: true }));
    closeCombobox(root);
    input.focus();
  }

  function scheduleFlashDismissal(): void {
    document.querySelectorAll<HTMLElement>("[data-incant-flash]").forEach((flash) => {
      if (flash.dataset.incantFlashScheduled) return;

      flash.dataset.incantFlashScheduled = "true";
      window.setTimeout(
        () => flash.querySelector<HTMLButtonElement>("[data-incant-flash-close]")?.click(),
        5000,
      );
    });
  }

  function openRevealDialogs(): void {
    document.querySelectorAll<HTMLDialogElement>("[data-incant-reveal-open]").forEach((dialog) => {
      if (dialog.open) return;
      dialog.removeAttribute("data-incant-reveal-open");
      wireDialogCancel(dialog, () => dismissRevealDialog(dialog));
      dialog.showModal();
      dialog.querySelector<HTMLElement>("[data-incant-reveal-dismiss]")?.focus();
    });
  }

  function dismissRevealDialog(dialog: HTMLDialogElement): void {
    dialog.close();
    dialog.querySelector<HTMLButtonElement>("[data-incant-reveal-dismiss]")?.click();
  }

  async function copyText(value: string): Promise<boolean> {
    if (navigator.clipboard?.writeText) {
      try {
        await navigator.clipboard.writeText(value);
        return true;
      } catch {
        // fall through to the legacy path (non-secure contexts, denied permission)
      }
    }

    const textarea = document.createElement("textarea");
    textarea.value = value;
    textarea.setAttribute("readonly", "true");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    let copied = false;
    try {
      copied = document.execCommand("copy");
    } catch {
      copied = false;
    }
    textarea.remove();
    return copied;
  }

  function observePageChanges(): void {
    scheduleFlashDismissal();
    openRevealDialogs();
  }

  applyTheme(preferredTheme());
  observePageChanges();
  syncNavigation(false);
  mobileNavigation.addEventListener("change", () => syncNavigation(false));
  new MutationObserver(observePageChanges).observe(document.body, { childList: true, subtree: true });

  document.addEventListener(
    "click",
    (event) => {
      if (confirmBypass) return;

      const target = eventElement(event);
      const trigger = target?.closest<HTMLElement>("[data-incant-confirm]");
      if (!trigger) return;

      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      let payload: ConfirmPayload = {};
      try {
        payload = JSON.parse(trigger.dataset.incantConfirm || "{}") as ConfirmPayload;
      } catch {
        payload = { message: trigger.dataset.incantConfirm };
      }
      openConfirmDialog(trigger, payload);
    },
    { capture: true },
  );

  document.addEventListener("click", (event) => {
    const target = eventElement(event);
    if (!target) return;

    if (target.closest("[data-incant-confirm-cancel]")) {
      closeConfirmDialog();
      return;
    }

    const revealCopy = target.closest<HTMLButtonElement>("[data-incant-reveal-copy]");
    if (revealCopy) {
      const value = revealCopy.dataset.incantRevealValueText || "";
      void copyText(value).then((ok) => {
        revealCopy.textContent = ok ? "Copied" : "Select + Ctrl+C";
        window.setTimeout(() => {
          revealCopy.textContent = "Copy";
        }, 1500);
      });
      return;
    }

    const revealDismiss = target.closest("[data-incant-reveal-dismiss]");
    if (revealDismiss) {
      revealDismiss.closest<HTMLDialogElement>("dialog")?.close();
    }

    if (target.closest("[data-incant-confirm-accept]")) {
      const source = confirmSource;
      closeConfirmDialog();
      if (source) {
        confirmBypass = true;
        source.click();
        confirmBypass = false;
      }
      return;
    }

    if (target instanceof HTMLDialogElement && target.matches("[data-incant-confirm-dialog]")) {
      closeConfirmDialog();
      return;
    }

    const comboboxOption = target.closest<HTMLButtonElement>("[data-incant-combobox-option]");
    const combobox = target.closest<HTMLElement>("[data-incant-combobox]");
    if (comboboxOption && combobox) {
      chooseComboboxOption(combobox, comboboxOption);
      return;
    }
    if (!combobox) closeOtherComboboxes();

    const filterOpen = target.closest<HTMLElement>("[data-incant-filter-open]");
    const dialogId = filterOpen?.dataset.incantFilterOpen;
    if (dialogId) {
      const dialog = document.getElementById(dialogId) as HTMLDialogElement | null;
      if (dialog?.showModal) {
        wireDialogCancel(dialog, () => dialog.close());
        dialog.showModal();

        const focusId = filterOpen.dataset.incantFilterFocus;
        if (focusId) {
          const input =
            (document.getElementById(focusId) as HTMLElement | null) ||
            (document.getElementById(`${focusId}-from`) as HTMLElement | null);
          const definition = input?.closest<HTMLDetailsElement>("[data-incant-filter-definition]");
          if (definition) definition.open = true;
          window.requestAnimationFrame(() => input?.focus());
        }
      }
    }

    const datePreset = target.closest<HTMLElement>("[data-incant-filter-date-preset]");
    if (datePreset) {
      const form = datePreset.closest<HTMLFormElement>("form");
      const days = Number(datePreset.dataset.incantFilterDatePreset);
      const range = recentDateRange(days);
      const fromInput = form?.querySelector<HTMLInputElement>('input[name$="[from]"]');
      const toInput = form?.querySelector<HTMLInputElement>('input[name$="[to]"]');
      if (fromInput) fromInput.value = range.from;
      if (toInput) toInput.value = range.to;
    }

    const filterClose = target.closest<HTMLElement>("[data-incant-filter-close], [data-incant-filter-apply]");
    if (filterClose) filterClose.closest<HTMLDialogElement>("dialog")?.close();

    if (target instanceof HTMLDialogElement && target.matches("[data-incant-filter-dialog]")) target.close();

    if (target.closest("[data-incant-theme-toggle]")) {
      const theme: Theme = document.documentElement.classList.contains("dark") ? "light" : "dark";
      window.localStorage.setItem(themeStorageKey, theme);
      applyTheme(theme);
    }

    if (target.closest("[data-incant-nav-toggle]")) toggleNavigation();
    if (target.closest("[data-incant-nav-backdrop], [data-incant-sidebar] a")) closeNavigation();

    const customRangeButton = target.closest("[data-incant-date-range-custom]");
    if (customRangeButton) {
      const fields = customRangeButton
        .closest("[data-incant-date-range]")
        ?.querySelector<HTMLElement>("[data-incant-date-range-fields]");
      fields?.classList.remove("hidden");
      fields?.querySelector<HTMLInputElement>("input")?.focus();
    }

    const applyRangeButton = target.closest("[data-incant-date-range-apply]");
    if (applyRangeButton) {
      applyRangeButton
        .closest("[data-incant-date-range-fields]")
        ?.querySelectorAll<HTMLInputElement>("input")
        .forEach((input) => input.dispatchEvent(new Event("change", { bubbles: true })));
    }
  });

  document.addEventListener("focusin", (event) => {
    const input = eventElement(event)?.closest<HTMLInputElement>("[data-incant-combobox-input]");
    const root = input?.closest<HTMLElement>("[data-incant-combobox]");
    if (root) openCombobox(root);
  });

  document.addEventListener("input", (event) => {
    const input = eventElement(event)?.closest<HTMLInputElement>("[data-incant-combobox-input]");
    const root = input?.closest<HTMLElement>("[data-incant-combobox]");
    if (root) openCombobox(root);
  });

  document.addEventListener("keydown", (event) => {
    const input = eventElement(event)?.closest<HTMLInputElement>("[data-incant-combobox-input]");
    const root = input?.closest<HTMLElement>("[data-incant-combobox]");

    if (input && root) {
      const options = visibleComboboxOptions(root);
      const activeId = input.getAttribute("aria-activedescendant");
      const activeIndex = options.findIndex((option) => option.id === activeId);

      if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        event.preventDefault();
        openCombobox(root);
        const nextIndex =
          event.key === "ArrowDown"
            ? activeIndex < 0
              ? 0
              : activeIndex + 1
            : activeIndex < 0
              ? options.length - 1
              : activeIndex - 1;
        activateComboboxOption(root, nextIndex);
        return;
      }

      if (event.key === "Enter" && activeIndex >= 0) {
        event.preventDefault();
        chooseComboboxOption(root, options[activeIndex]);
        return;
      }

      if (event.key === "Escape") {
        event.preventDefault();
        closeCombobox(root);
        return;
      }

      if (event.key === "Tab") closeCombobox(root);
    }

    if (event.key === "Escape" && shell()?.classList.contains("incant-nav-open")) {
      closeNavigation({ restoreFocus: true });
    }
  });

  window.addEventListener("phx:page-loading-stop", () => {
    applyTheme(preferredTheme());
    scheduleFlashDismissal();
    closeNavigation();
  });
}
