type Inputs = {
    driverRoleInputElement: HTMLInputElement | null;
    driverQualificationInputElements: NodeListOf<HTMLInputElement>;
}

function updateInputs({ driverRoleInputElement, driverQualificationInputElements }: Inputs) {
    if (!driverRoleInputElement) return;

    const enabled = driverRoleInputElement.checked;
    driverQualificationInputElements.forEach((input) => {
        input.disabled = !enabled;
        if (!enabled) {
            input.checked = false;
        }
    });
}

export function toggleDriverQualificationInputs({
    driverRoleInputElement,
    driverQualificationInputElements,
}: Inputs) {
    if (!driverRoleInputElement || driverQualificationInputElements.length === 0) return;

    driverRoleInputElement.addEventListener("change", () => {
        updateInputs({ driverRoleInputElement, driverQualificationInputElements });
    });

    updateInputs({ driverRoleInputElement, driverQualificationInputElements });
}
