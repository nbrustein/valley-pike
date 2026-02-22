const BASIC_NAME_PATTERN = /^[A-Za-z .'-]+$/;

// If the name includes non-basic characters (e.g. Chinese), prefer the full name.
// Otherwise, assume the preferred name is everything before the first whitespace.
export function getDefaultPreferredName(fullName: string) {
  if (fullName.length === 0) return "";

  if (!BASIC_NAME_PATTERN.test(fullName)) return fullName;

  const trimmed = fullName.trim();
  if (trimmed.length === 0) return "";

  return trimmed.split(/\s+/)[0];
}
