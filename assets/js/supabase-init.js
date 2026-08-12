// Datos del proyecto de Supabase (Project Settings -> API).
// La publishable key es pública (segura para el navegador) porque
// todas las tablas exigen sesión iniciada (RLS "solo autenticados").
const SUPABASE_URL = 'https://jfdwqcevdsvwvgasmxpo.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_D-uL_ywKy5KoaHVhcYN0oA_V2CIVXVY';

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
