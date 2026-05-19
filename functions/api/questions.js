// GET /api/questions  → liste toutes les questions
// POST /api/questions → creer une nouvelle question
export async function onRequest(context) {
  var request = context.request;
  var env = context.env;

  if (request.method === 'GET') {
    var data = await env.QUESTIONS_KV.get('questions', 'json');
    return Response.json(data || []);
  }

  if (request.method === 'POST') {
    var body;
    try { body = await request.json(); }
    catch (e) { return new Response('Corps invalide', { status: 400 }); }

    if (!body.auteur || !body.texte) {
      return new Response('Auteur et texte requis', { status: 400 });
    }

    var questions = (await env.QUESTIONS_KV.get('questions', 'json')) || [];
    var question = {
      id: Date.now().toString(),
      auteur: body.auteur,
      texte: body.texte,
      date: new Date().toISOString(),
      reponse: null,
      auteur_reponse: null,
      date_reponse: null
    };
    questions.unshift(question);
    await env.QUESTIONS_KV.put('questions', JSON.stringify(questions));
    return Response.json(question, { status: 201 });
  }

  return new Response('Methode non autorisee', { status: 405 });
}
