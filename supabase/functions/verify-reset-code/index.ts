import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

async function findUserByEmail(
  supabase: {
    auth: {
      admin: {
        listUsers: (params: { page: number; perPage: number }) => Promise<{
          data: { users: Array<{ email?: string | null; id: string }> };
          error: { message: string } | null;
        }>;
      };
    };
  },
  email: string,
) {
  const perPage = 1000;

  for (let page = 1; page <= 20; page++) {
    const { data, error } = await supabase.auth.admin.listUsers({
      page,
      perPage,
    });

    if (error) {
      return { user: null, error };
    }

    const user = data.users.find((u) => u.email?.toLowerCase() === email);
    if (user) {
      return { user, error: null };
    }

    if (data.users.length < perPage) {
      return { user: null, error: null };
    }
  }

  return { user: null, error: null };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 取环境变量（兼容新旧两种格式）
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS");
    const legacyKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    let adminKey = "";
    if (secretKeysRaw) {
      try {
        const parsed = JSON.parse(secretKeysRaw);
        adminKey = parsed["default"] || Object.values(parsed)[0] || "";
      } catch (_) {}
    }
    if (!adminKey && legacyKey) {
      adminKey = legacyKey;
    }

    if (!supabaseUrl || !adminKey) {
      return new Response(
        JSON.stringify({ success: false, error: "服务器配置错误" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const { email, code, newPassword } = await req.json();

    if (!email || !code || !newPassword) {
      return new Response(
        JSON.stringify({ success: false, error: "参数不完整" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (!/^\d{6}$/.test(code)) {
      return new Response(
        JSON.stringify({ success: false, error: "验证码必须是 6 位数字" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (newPassword.length < 6) {
      return new Response(
        JSON.stringify({ success: false, error: "密码长度至少为 6 位" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const normalizedEmail = email.trim().toLowerCase();
    const supabase = createClient(supabaseUrl, adminKey);

    const { data: records, error: queryError } = await supabase
      .from("password_reset_codes")
      .select("*")
      .eq("email", normalizedEmail)
      .eq("code", code)
      .eq("used", false)
      .gte("expires_at", new Date().toISOString())
      .order("created_at", { ascending: false })
      .limit(1);

    if (queryError) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "验证码校验失败: " + queryError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (!records || records.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: "验证码错误或已过期" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    await supabase
      .from("password_reset_codes")
      .update({ used: true })
      .eq("id", records[0].id);

    const { user, error: listError } = await findUserByEmail(
      supabase,
      normalizedEmail,
    );
    if (listError) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "查询用户失败: " + listError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (!user) {
      return new Response(
        JSON.stringify({ success: false, error: "用户不存在" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const { error: updateError } = await supabase.auth.admin.updateUserById(
      user.id,
      { password: newPassword },
    );

    if (updateError) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "密码更新失败: " + updateError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({ success: true, message: "密码重置成功" }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ success: false, error: "异常: " + String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
