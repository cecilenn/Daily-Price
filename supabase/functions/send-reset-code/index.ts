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
          data: { users: Array<{ email?: string | null }> };
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

async function resendErrorMessage(response: Response) {
  const text = await response.text();
  let message = text;

  try {
    const data = JSON.parse(text);
    if (typeof data?.message === "string") {
      message = data.message;
    }
  } catch (_) {
    // Resend usually returns JSON, but keep the raw body if it does not.
  }

  if (
    response.status === 403 &&
    message.includes("You can only send testing emails")
  ) {
    return "邮件服务还在 Resend 测试模式，只能发送到发信账号自己的邮箱。请先在 Resend 验证发信域名，并在 Supabase 配置 RESEND_FROM。";
  }

  return "邮件发送失败: " + message;
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
    const resendKey = Deno.env.get("RESEND_API_KEY");

    // 找可用的 admin key：新版优先，旧版 fallback
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

    // 关键变量缺失 → 返回调试信息
    if (!supabaseUrl || !adminKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "服务器配置错误",
          debug: {
            hasUrl: !!supabaseUrl,
            hasSecretKeys: !!secretKeysRaw,
            hasLegacyKey: !!legacyKey,
            hasResendKey: !!resendKey,
          },
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const { email } = await req.json();

    if (!email || !/^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$/.test(email)) {
      return new Response(
        JSON.stringify({ success: false, error: "请输入有效的邮箱地址" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const normalizedEmail = email.trim().toLowerCase();
    const supabase = createClient(supabaseUrl, adminKey);

    // 检查邮箱是否已注册
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
        JSON.stringify({ success: false, error: "该邮箱未注册" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 60 秒限频
    const oneMinuteAgo = new Date(Date.now() - 60_000).toISOString();
    const { data: recent } = await supabase
      .from("password_reset_codes")
      .select("id")
      .eq("email", normalizedEmail)
      .gte("created_at", oneMinuteAgo)
      .limit(1);

    if (recent && recent.length > 0) {
      return new Response(
        JSON.stringify({ success: false, error: "请等待 60 秒后重试" }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 生成验证码
    const code = String(Math.floor(100000 + Math.random() * 900000));
    const expiresAt = new Date(Date.now() + 5 * 60_000).toISOString();

    const { data: insertedCode, error: insertError } = await supabase
      .from("password_reset_codes")
      .insert({ email: normalizedEmail, code, expires_at: expiresAt })
      .select("id")
      .single();

    if (insertError) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "保存验证码失败: " + insertError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 发邮件
    if (!resendKey) {
      return new Response(
        JSON.stringify({ success: false, error: "RESEND_API_KEY 未配置" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: Deno.env.get("RESEND_FROM") ||
          "Daily Price <onboarding@resend.dev>",
        to: [normalizedEmail],
        subject: "【Daily Price】密码重置验证码",
        html: `
          <div style="font-family: sans-serif; max-width: 400px; margin: 0 auto; padding: 24px;">
            <h2 style="text-align: center; color: #1a73e8;">Daily Price</h2>
            <p>您正在重置密码，验证码为：</p>
            <div style="text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #333; padding: 16px; background: #f5f5f5; border-radius: 8px;">
              ${code}
            </div>
            <p style="color: #666; font-size: 13px;">验证码 5 分钟内有效，请勿泄露给他人。</p>
          </div>
        `,
      }),
    });

    if (!resendRes.ok) {
      const error = await resendErrorMessage(resendRes);
      if (insertedCode?.id) {
        await supabase
          .from("password_reset_codes")
          .delete()
          .eq("id", insertedCode.id);
      }
      return new Response(
        JSON.stringify({ success: false, error }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({ success: true, message: "验证码已发送" }),
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
