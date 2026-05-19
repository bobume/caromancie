var ARNAUD_EMAIL = 'seoleonplus@gmail.com';

export async function onRequest({ request, env }) {
  var url = new URL(request.url);
  var email = request.headers.get('CF-Access-Authenticated-User-Email') || '';

  if (request.method === 'GET') {
    var mois = url.searchParams.get('mois');
    if (!mois) return new Response('Parametre mois manquant', { status: 400 });
    var existants = await env.QUESTIONS_KV.get('effaces:' + mois, 'json') || [];
    return Response.json(existants);
  }

  if (request.method === 'POST') {
    if (email !== ARNAUD_EMAIL) return new Response('Interdit', { status: 403 });
    var body = await request.json();
    var moisPost = body.mois;
    var hash = body.hash;
    if (!moisPost || !hash) return new Response('Donnees manquantes', { status: 400 });
    var liste = await env.QUESTIONS_KV.get('effaces:' + moisPost, 'json') || [];
    if (liste.indexOf(hash) === -1) liste.push(hash);
    await env.QUESTIONS_KV.put('effaces:' + moisPost, JSON.stringify(liste));
    return Response.json({ ok: true });
  }

  return new Response('Methode non supportee', { status: 405 });
}
