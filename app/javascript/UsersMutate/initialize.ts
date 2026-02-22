import { toggleOrgAdminUserRolesInputsVisibility } from "./toggleOrgAdminUserRolesInputsVisibility";
import { syncPreferredName } from "./syncPreferredName";

type Inputs = {
    organizationRolesElement: HTMLElement;
    globalRoleInputElement: NodeListOf<HTMLInputElement>;
    fullNameInputElement: HTMLInputElement | null;
    preferredNameInputElement: HTMLInputElement | null;
}
export function initialize({
    organizationRolesElement,
    globalRoleInputElement,
    fullNameInputElement,
    preferredNameInputElement,
}: Inputs) {
    toggleOrgAdminUserRolesInputsVisibility({ organizationRolesElement, globalRoleInputElement })
    syncPreferredName({ fullNameInputElement, preferredNameInputElement })
}
