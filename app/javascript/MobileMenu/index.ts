import { toggle } from "./toggle";

export function initMobileMenu(): void {
  const btn = document.querySelector<HTMLElement>("[data-mobile-menu-toggle]");
  const menu = document.querySelector<HTMLElement>("[data-mobile-menu]");
  if (!btn || !menu) return;

  btn.addEventListener("click", () => toggle(menu));

  document.addEventListener("click", (e) => {
    const target = e.target as Node;
    if (!btn.contains(target) && !menu.contains(target)) {
      menu.classList.add("hidden");
    }
  });

  menu.addEventListener("click", (e) => {
    if ((e.target as HTMLElement).closest("a")) {
      menu.classList.add("hidden");
    }
  });
}
