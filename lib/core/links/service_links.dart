// Public service entry only. Never append app session or profile data.
const legendStudyLabUrl = 'https://lab.legendstudy.com';

/// Fail closed: only the canonical HTTPS root is an app-owned LAB entry.
Uri? legendStudyLabEntryUri(String value) =>
    value == legendStudyLabUrl ? Uri.parse(legendStudyLabUrl) : null;
