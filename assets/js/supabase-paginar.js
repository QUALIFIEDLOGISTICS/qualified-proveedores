// Lecturas completas aunque la tabla crezca.
// Supabase devuelve como MUCHO 1000 filas por consulta y corta el resto sin avisar: así llegaron a perderse artículos y partidas de stock
// cuando el almacén superó las 1000. Aquí se arregla para siempre y para TODAS las lecturas de la web:
//   · toda consulta  supabaseClient.from('tabla').select(...)  que no pida un tramo concreto (range, limit, single, maybeSingle, csv) se hace
//     como siempre; si la respuesta llega justo al tope de 1000, se vuelve a pedir por páginas hasta traer todas las filas (ordenadas por su id
//     para que ninguna se salte ni se repita entre página y página).
//   · lo normal (menos de 1000 filas) no cuesta nada extra.
// Las consultas que ya piden por páginas o con límite propio no se tocan. Se carga justo después de supabase-init.js.
(function () {
  if (typeof supabaseClient === 'undefined' || supabaseClient.__paginaAutomatica) return;
  const TAM = 1000;          // lo máximo que devuelve Supabase de una vez
  const MAX_PAGINAS = 200;   // tope de seguridad: 200.000 filas
  const desde0 = supabaseClient.from.bind(supabaseClient);

  supabaseClient.from = function (tabla) {
    const qb = desde0(tabla);
    const select0 = qb.select.bind(qb);
    qb.select = function (columnas, opciones) {
      const b = select0(columnas, opciones);
      if ((opciones && opciones.head) || !b || typeof b !== 'object') return b;   // solo contar: no hay filas que paginar
      let manual = false;                 // quien llama ya pide un tramo concreto
      const originales = {};
      ['range', 'limit', 'single', 'maybeSingle', 'csv', 'explain'].forEach(m => {
        if (typeof b[m] !== 'function') return;
        originales[m] = b[m];
        b[m] = function () { manual = true; return originales[m].apply(this, arguments); };
      });
      let p = b;
      while (p && !Object.prototype.hasOwnProperty.call(p, 'then')) p = Object.getPrototypeOf(p);
      if (!p || typeof p.then !== 'function' || !originales.range) return b;
      const then0 = p.then;
      const lanzar = () => new Promise((ok, ko) => then0.call(b, ok, ko));

      b.then = function (ok, ko) {
        const trabajo = (async () => {
          const r = await lanzar();
          if (manual || !r || r.error || !Array.isArray(r.data) || r.data.length < TAM) return r;
          // Llegó al tope: se piden todas las páginas
          const url = b.url, ordenOriginal = url && url.searchParams ? url.searchParams.get('order') : null;
          const poner = conId => {
            if (!url || !url.searchParams) return;
            const o = conId ? (ordenOriginal ? ordenOriginal + ',id.asc' : 'id.asc') : ordenOriginal;
            if (o) url.searchParams.set('order', o); else url.searchParams.delete('order');
          };
          const paginar = async conId => {
            poner(conId);
            const filas = [];
            for (let n = 0; n < MAX_PAGINAS; n++) {
              originales.range.call(b, n * TAM, n * TAM + TAM - 1);
              const pag = await lanzar();
              if (pag.error) return { error: pag.error };
              filas.push(...(pag.data || []));
              if ((pag.data || []).length < TAM) break;
            }
            return { data: filas };
          };
          let res = await paginar(true);
          if (res.error) res = await paginar(false);   // una tabla sin columna «id»: se pagina con su propio orden
          if (res.error) return r;                     // no se pudo: se devuelve lo primero (como antes)
          try { console.info(`[Supabase] «${tabla}» tiene más de ${TAM} filas: leída por páginas (${res.data.length} filas).`); } catch (e) { /* sin consola */ }
          return Object.assign({}, r, { data: res.data });
        })();
        return trabajo.then(ok, ko);
      };
      return b;
    };
    return qb;
  };
  supabaseClient.__paginaAutomatica = true;
})();
