import "@hotwired/turbo-rails"
import { usersMutate } from "./UsersMutate";
import { initMobileMenu } from "./MobileMenu";

window.usersMutate = usersMutate;

document.addEventListener("turbo:load", initMobileMenu);
