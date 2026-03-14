import { toggle } from "./toggle";

export function initMobileMenu(): void {
  const btn = document.querySelector<HTMLElement>("[data-mobile-menu-toggle]");
  const menu = document.querySelector<HTMLElement>("[data-mobile-menu]");
  if (!btn || !menu) return;

  btn.addEventListener("click", () => toggle(menu));
}
