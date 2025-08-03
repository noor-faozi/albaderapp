import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  try {
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");

    if (!serviceRoleKey || !supabaseUrl) {
      console.error("❌ Missing env vars:", {
        SUPABASE_SERVICE_ROLE_KEY: serviceRoleKey,
        SUPABASE_URL: supabaseUrl,
      });
      return new Response("Missing env vars", { status: 500 });
    }

    console.log("✅ Loaded service role key (starts with):", serviceRoleKey.slice(0, 6));

    const requestBody = await req.json();

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    const { email, password, metadata } = requestBody;

    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: metadata ?? {},
    });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({
      message: 'User created successfully',
      user: data.user,
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
