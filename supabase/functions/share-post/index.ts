import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const postId = url.searchParams.get('post_id');

  if (!postId) {
    return new Response('Missing post_id', { status: 400, headers: corsHeaders });
  }

  // Initialize Supabase client
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // Fetch post details along with user username/avatar
  const { data: post, error } = await supabase
    .from('doubt_posts')
    .select(`
      title,
      body,
      image_urls,
      user_profiles (
        username,
        avatar_url
      )
    `)
    .eq('id', postId)
    .maybeSingle();

  if (error || !post) {
    return new Response('Post not found', { status: 404, headers: corsHeaders });
  }

  const title = post.title || 'Focus Fox Post';
  // Truncate body for description
  const description = post.body ? (post.body.length > 150 ? post.body.substring(0, 150) + '...' : post.body) : 'Join the discussion on Focus Fox!';
  // Get first image if available
  const imageUrl = (post.image_urls && post.image_urls.length > 0) ? post.image_urls[0] : 'https://raw.githubusercontent.com/lostrunes/assets/main/focus_fox_icon.png'; // fallback icon
  const authorName = post.user_profiles?.username || 'Focus Fox User';

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  
  <!-- Open Graph / Facebook Meta Tags -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${description}">
  <meta property="og:image" content="${imageUrl}">
  <meta property="og:url" content="${req.url}">
  
  <!-- Twitter Meta Tags -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${title}">
  <meta name="twitter:description" content="${description}">
  <meta name="twitter:image" content="${imageUrl}">

  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: #f3f4f6;
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      color: #1f2937;
    }
    .card {
      background-color: #ffffff;
      border-radius: 16px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
      width: 90%;
      max-width: 500px;
      padding: 24px;
      box-sizing: border-box;
      text-align: center;
    }
    .avatar {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background-color: #e5e7eb;
      margin: 0 auto 16px auto;
      object-fit: cover;
      border: 2px solid #7D4B26;
    }
    .author {
      font-weight: bold;
      color: #4b5563;
      margin-bottom: 8px;
    }
    .title {
      font-size: 22px;
      font-weight: 800;
      color: #111827;
      margin-bottom: 12px;
      line-height: 1.3;
    }
    .body {
      font-size: 16px;
      color: #374151;
      line-height: 1.6;
      margin-bottom: 24px;
      text-align: left;
      white-space: pre-wrap;
    }
    .post-img {
      width: 100%;
      max-height: 300px;
      border-radius: 12px;
      object-fit: cover;
      margin-bottom: 20px;
    }
    .btn {
      display: inline-block;
      background-color: #7D4B26;
      color: #ffffff;
      font-weight: bold;
      padding: 14px 28px;
      border-radius: 12px;
      text-decoration: none;
      transition: background-color 0.2s;
    }
    .btn:hover {
      background-color: #633b1e;
    }
  </style>

  <script>
    // Deep link redirection script
    function redirect() {
      const postId = "${postId}";
      const appSchemeUrl = "focusfox://posts/" + postId;
      
      // Attempt to open custom scheme
      window.location.href = appSchemeUrl;
      
      // Fallback redirect to store after timeout
      setTimeout(() => {
        // If still on this page after 2.5s, redirect to app store or show download notice
        console.log("Redirect timeout. User might not have the app.");
      }, 2500);
    }
    window.onload = redirect;
  </script>
</head>
<body>
  <div class="card">
    ${post.user_profiles?.avatar_url ? `<img class="avatar" src="${post.user_profiles.avatar_url}" alt="Avatar">` : `<div class="avatar" style="line-height:60px;font-weight:bold;color:#7D4B26;font-size:24px;">F</div>`}
    <div class="author">Posted by @${authorName}</div>
    <div class="title">${title}</div>
    ${post.image_urls && post.image_urls.length > 0 ? `<img class="post-img" src="${post.image_urls[0]}" alt="Post Image">` : ''}
    <div class="body">${post.body || ''}</div>
    <a href="https://play.google.com/store/apps/details?id=com.reva.focusfox" class="btn">Open in Focus Fox App</a>
  </div>
</body>
</html>`;

  return new Response(html, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/html; charset=utf-8',
    },
  });
});
