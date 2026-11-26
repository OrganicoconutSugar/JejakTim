// Supabase Edge Function: team-insight
// Deploy: supabase functions deploy team-insight
// Secret: supabase secrets set GEMINI_API_KEY=your_key_here
// Optional: supabase secrets set GEMINI_MODEL=gemini-2.5-flash

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SYSTEM_INSTRUCTION = `Kamu adalah asisten koordinasi tim untuk aplikasi mahasiswa bernama JejakTim.
Prinsip wajib:
- Gunakan bahasa Indonesia yang hangat, ringkas, suportif, dan praktis.
- DILARANG memberi skor, ranking, nilai akademik, atau label menghakimi pada anggota.
- Gunakan hanya data agregat yang diberikan. Jangan mengarang fakta di luar data.
- Fokus pada keseimbangan beban kerja, tugas menunggu review, revisi, kendala (blocker), dan tenggat mendekat.
- Jawab HANYA dalam JSON valid dengan struktur persis:
{
  "headline": "Ringkasan singkat 4-8 kata",
  "summary": "2-3 kalimat suportif tentang ritme kerja tim saat ini.",
  "highlights": ["Temuan positif atau kondisi utama (maks 3 item)"],
  "recommendations": [
    {
      "title": "Judul langkah singkat",
      "detail": "Saran koordinasi konkret untuk tim",
      "taskRef": "T1 atau null",
      "priority": "high | medium | calm"
    }
  ]
}`;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
    if (!apiKey) {
      return new Response(
        JSON.stringify({
          error: "GEMINI_API_KEY belum diatur di Supabase Secrets.",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Autentikasi diperlukan." }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const payload = await req.json();
    const preferredModel =
      Deno.env.get("GEMINI_MODEL")?.trim() || "gemini-flash-lite-latest";
    const modelsToTry = [
      preferredModel,
      ...[
        "gemini-flash-lite-latest",
        "gemini-flash-latest",
        "gemini-3-flash-preview",
        "gemini-2.5-flash-lite",
      ].filter((m) => m !== preferredModel),
    ];

    const promptText =
      "Analisis data agregat proyek mahasiswa berikut dan berikan saran koordinasi tim:\n" +
      JSON.stringify(payload);

    let geminiResp: Response | null = null;
    let activeModel = preferredModel;
    for (const model of modelsToTry) {
      activeModel = model;
      const endpoint =
        `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
      const resp = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: SYSTEM_INSTRUCTION }] },
          contents: [{ role: "user", parts: [{ text: promptText }] }],
          generationConfig: {
            temperature: 0.4,
            responseMimeType: "application/json",
          },
        }),
      });
      geminiResp = resp;
      if (resp.ok || ![404, 429, 500, 503].includes(resp.status)) {
        break;
      }
    }

    if (!geminiResp || !geminiResp.ok) {
      const errBody = geminiResp ? await geminiResp.text() : "No response";
      return new Response(
        JSON.stringify({
          error: "Layanan Gemini belum merespons.",
          status: geminiResp?.status ?? 502,
          detail: errBody.slice(0, 300),
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const data = await geminiResp.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const parsed = JSON.parse(text);

    return new Response(
      JSON.stringify({
        ...parsed,
        model: activeModel,
        provider: "supabase-edge-gemini",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: "Gagal memproses analisis AI.",
        detail: err instanceof Error ? err.message : String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
