var ARNAUD_EMAIL = 'seoleonplus@gmail.com';

export async function onRequest({ request }) {
  var email = request.headers.get('CF-Access-Authenticated-User-Email') || '';
  var nom = email === ARNAUD_EMAIL ? 'Arnaud' : 'Carole';
  return Response.json({ email: email, nom: nom });
}
