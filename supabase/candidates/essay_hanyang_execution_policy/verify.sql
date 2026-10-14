-- Read-only; no claim, Provider or Credit call.
select r.exam_id,r.revision,r.state,r.approval_requested,
 r.body->'package'->>'package_digest' as package_digest,
 ((r.body->'package'->>'package_digest')=encode(sha256(convert_to(((r.body->'package')-'package_digest')::text,'UTF8')),'hex')) as hash_valid,
 (select bool_and(r.body->'rights'->d->>'providerTransmission'='APPROVED') from jsonb_array_elements_text(r.body->'documents') as t(d)) as documents_transmission_approved,
 essay_exam_private.runtime_policy(r.exam_id) as runtime_policy,
 essay_private.provider_policy(essay_exam_private.runtime_policy(r.exam_id)->>'regime') as provider_binding
from essay_material_private.reviews r where r.exam_id='345d3caa-3438-58c3-8f80-62a6242179ec';
