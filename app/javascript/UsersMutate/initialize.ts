import { toggleOrgAdminUserRolesInputsVisibility } from "./toggleOrgAdminUserRolesInputsVisibility";

type Inputs = {
    organizationRolesElement: HTMLElement;
    globalRoleInputElement: NodeListOf<HTMLInputElement>;
}
export function initialize({ organizationRolesElement, globalRoleInputElement }: Inputs) {
    toggleOrgAdminUserRolesInputsVisibility({ organizationRolesElement, globalRoleInputElement })
}