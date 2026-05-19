// PATCH /api/questions/:id → ajouter une reponse a une question
export async function onRequest(context) {
  var request = context.request;
  var env = context.env;
  var id = context.params.id;

  if (request.method === 'PATCH') {
    var body;
    try { body = await request.json(); }
    catch (e) { return new Response('Corps invalide', { status: 400 }); }

    if (!body.auteur || !body.reponse) {
      return new Response('Auteur et reponse requis', { status: 400 });
    }

    var questions = (await env.QUESTIONS_KV.get('questions', 'json')) || [];
    var idx = questions.findIndex(function(q) { return q.id === id; });
    if (idx === -1) {
      return new Response('Question introuvable', { status: 404 });
    }

    questions[idx].reponse = body.reponse;
    questions[idx].auteur_reponse = body.auteur;
    questions[idx].date_reponse = new Date().toISOString();

    await env.QUESTIONS_KV.put('questions', JSON.stringify(questions));
    return Response.json(questions[idx]);
  }

  return new Response('Methode non autorisee', { status: 405 });
}
