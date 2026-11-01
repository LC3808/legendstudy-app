-- Disable report only. Original learning, Credit and History remain untouched.
revoke execute on function public.admin_learning_analytics(timestamptz,timestamptz) from authenticated;
