// Datos del proyecto de Supabase (Project Settings -> API).
// La publishable key es pública (segura para el navegador) porque
// todas las tablas exigen sesión iniciada (RLS "solo autenticados").
const SUPABASE_URL = 'https://jfdwqcevdsvwvgasmxpo.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_D-uL_ywKy5KoaHVhcYN0oA_V2CIVXVY';

// La sesión se guarda solo mientras el navegador siga abierto (sessionStorage),
// no para siempre (localStorage, el valor por defecto): en un ordenador
// compartido, al cerrar el navegador la sesión desaparece, así que la
// siguiente persona que entre desde el mismo favorito ve el login en vez de
// entrar con la cuenta de quien lo usó antes.
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { storage: window.sessionStorage },
});
