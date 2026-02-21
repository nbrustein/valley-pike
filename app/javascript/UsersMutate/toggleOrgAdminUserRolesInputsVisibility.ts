import { VANITA_VIEWER } from 'UserRole';

type Inputs = {
    organizationRolesElement: HTMLElement;
    globalRoleInputElement: NodeListOf<HTMLInputElement>;
}

function updateVisibility({ organizationRolesElement, globalRoleInputElement }: Inputs) {
    const selected = Array.from(globalRoleInputElement).find((input) => input.checked);
    const value = selected ? selected.value : null;
    const shouldShow = value === "" || value === VANITA_VIEWER;
    organizationRolesElement.style.display = shouldShow ? "block" : "none";
}

export function toggleOrgAdminUserRolesInputsVisibility({ organizationRolesElement, globalRoleInputElement }: Inputs) {
    if (!organizationRolesElement || globalRoleInputElement.length === 0) return;

    globalRoleInputElement.forEach((input) => {
        input.addEventListener("change", () => updateVisibility({ organizationRolesElement, globalRoleInputElement }));
    });
    updateVisibility({ organizationRolesElement, globalRoleInputElement });
}