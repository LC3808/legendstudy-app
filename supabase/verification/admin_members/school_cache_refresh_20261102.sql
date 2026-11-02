-- Existing NEIS proxy exact office/code matches verified 2026-11-02 KST.
-- Display metadata only. No profiles, Credit, payment or user history writes.
BEGIN;
INSERT INTO student_private.school_display_cache
 (office_code,school_code,school_name,source,resolved_at)
SELECT v.office_code,v.school_code,v.school_name,'NEIS',now()
FROM (VALUES
 ('J10','7530135','행신고등학교'),
 ('K10','7801132','민족사관고등학교'),
 ('N10','8140094','신평고등학교'),
 ('P10','8321115','군산제일고등학교'),
 ('R10','8750127','점촌고등학교')
) AS v(office_code,school_code,school_name)
ON CONFLICT (office_code,school_code) DO NOTHING;
SELECT count(*) AS unresolved_profiles
FROM public.profiles p
LEFT JOIN student_private.school_display_cache c
 ON c.office_code=p.neis_office_code AND c.school_code=p.neis_school_code
WHERE p.neis_school_code IS NOT NULL AND c.school_name IS NULL;
COMMIT;
