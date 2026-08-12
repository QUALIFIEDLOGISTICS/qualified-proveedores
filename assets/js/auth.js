async function doLogin(email, password){
  const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
  return { data, error };
}

async function getCurrentSession(){
  const { data, error } = await supabaseClient.auth.getSession();
  if (error) return null;
  return data.session;
}

async function handleLogout(){
  await supabaseClient.auth.signOut();
  window.location.href = 'index.html';
}

function authErrorMessage(error){
  if (!error) return '';
  const msg = error.message || '';
  if (msg.includes('Invalid login credentials')) return 'Correo o contraseña incorrectos.';
  if (msg.includes('Unable to validate email') || msg.includes('invalid')) return 'Introduce un correo electrónico válido.';
  return msg || 'Ha ocurrido un error. Inténtalo de nuevo.';
}
