import { toggleOrgAdminUserRolesInputsVisibility } from "./toggleOrgAdminUserRolesInputsVisibility";
import { syncPreferredName } from "./syncPreferredName";
import { toggleDriverQualificationInputs } from "./toggleDriverQualificationInputs";

type Inputs = {
    organizationRolesElement: HTMLElement;
    globalRoleInputElement: NodeListOf<HTMLInputElement>;
    fullNameInputElement: HTMLInputElement | null;
    preferredNameInputElement: HTMLInputElement | null;
    driverRoleInputElement: HTMLInputElement | null;
    driverQualificationInputElements: NodeListOf<HTMLInputElement>;
}
export function initialize({
    organizationRolesElement,
    globalRoleInputElement,
    fullNameInputElement,
    preferredNameInputElement,
    driverRoleInputElement,
    driverQualificationInputElements,
}: Inputs) {
    toggleOrgAdminUserRolesInputsVisibility({ organizationRolesElement, globalRoleInputElement })
    syncPreferredName({ fullNameInputElement, preferredNameInputElement })
    toggleDriverQualificationInputs({ driverRoleInputElement, driverQualificationInputElements })
}
