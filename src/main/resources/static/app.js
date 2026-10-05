'use strict';
let csrf, clientes=[], contas=[], editing=null;
const $=id=>document.getElementById(id);
const esc=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const money=value=>Number(value).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
async function api(path,method='GET',body){
  const headers={'Accept':'application/json'};
  if(body!==undefined)headers['Content-Type']='application/json';
  if(method!=='GET'&&csrf)headers[csrf.headerName]=csrf.token;
  const r=await fetch(path,{method,headers,body:body===undefined?undefined:JSON.stringify(body)});
  if(r.status===401||r.redirected){location.href='/login';throw Error('Entre novamente.');}
  if(!r.ok){const e=await r.json().catch(()=>({}));throw Error(e.message||`Operação recusada (${r.status}). Atualize a página se a sessão expirou.`);}
  return r.status===204?null:r.json();
}
function notice(message,error=false){$('notice').hidden=false;$('notice').className=error?'error':'';$('notice').textContent=message;}
async function refresh(){
  [clientes,contas]=await Promise.all([api('/api/clientes'),api('/api/contas')]);
  $('totalClientes').textContent=clientes.length;$('totalContas').textContent=contas.length;
  const actions=(type,id)=>`<button data-action="edit" data-type="${type}" data-id="${id}">Editar</button><button class="danger" data-action="delete" data-type="${type}" data-id="${id}">Excluir</button>`;
  $('clientes').innerHTML=clientes.map(c=>`<tr><td>#${c.id}</td><td>${esc(c.nome)}</td><td>${esc(c.email)}</td><td>${actions('clientes',c.id)}</td></tr>`).join('')||'<tr><td colspan="4" class="empty">Seu primeiro relacionamento começa aqui. Cadastre um cliente.</td></tr>';
  $('contas').innerHTML=contas.map(c=>`<tr><td>#${c.id}</td><td>${esc(c.numero)}</td><td>${esc(c.clienteNome)} <small>#${c.clienteId}</small></td><td>${money(c.saldo)}</td><td>${actions('contas',c.id)}</td></tr>`).join('')||'<tr><td colspan="5" class="empty">Cadastre um cliente e vincule uma conta a ele.</td></tr>';
}
function openForm(type,item){
  if(type==='contas'&&!clientes.length){notice('Cadastre um cliente antes de criar uma conta.',true);return;}
  editing={type,id:item?.id};$('formError').textContent='';
  $('formTitle').textContent=(item?'Editar ':'Novo cadastro de ')+(type==='clientes'?'cliente':'conta');
  $('fields').innerHTML=type==='clientes'
    ?'<label for="nome">Nome</label><input id="nome" name="nome" required maxlength="100"><label for="email">E-mail</label><input id="email" name="email" type="email" required maxlength="150">'
    :'<label for="clienteId">Cliente</label><select id="clienteId" name="clienteId" required></select><label for="numero">Número da conta</label><input id="numero" name="numero" required maxlength="20"><label for="saldo">Saldo (R$)</label><input id="saldo" name="saldo" type="number" min="0" max="9999999999999.99" step="0.01" value="0.00" required>';
  if(type==='contas')$('clienteId').innerHTML=clientes.map(c=>`<option value="${c.id}">#${c.id} · ${esc(c.nome)}</option>`).join('');
  if(item)for(const key of(type==='clientes'?['nome','email']:['clienteId','numero','saldo']))$(key).value=item[key];
  $('editor').showModal();
}
$('newCliente').onclick=()=>openForm('clientes');$('newConta').onclick=()=>openForm('contas');
$('close').onclick=$('cancel').onclick=()=>$('editor').close();
$('form').onsubmit=async event=>{
  event.preventDefault();$('save').disabled=true;$('formError').textContent='';
  try{
    const body=Object.fromEntries(new FormData(event.target));
    if(editing.type==='contas'){body.clienteId=Number(body.clienteId);body.saldo=Number(body.saldo);}
    await api(`/api/${editing.type}${editing.id?'/'+editing.id:''}`,editing.id?'PUT':'POST',body);
    $('editor').close();await refresh();notice('Registro salvo. Lista atualizada com os dados do banco.');
  }catch(e){$('formError').textContent=e.message;}finally{$('save').disabled=false;}
};
document.querySelector('main').addEventListener('click',async event=>{
  const b=event.target.closest('button[data-action]');if(!b)return;
  const {action,type,id}=b.dataset;
  if(action==='edit')return openForm(type,(type==='clientes'?clientes:contas).find(c=>c.id===Number(id)));
  if(!confirm(`Excluir ${type==='clientes'?'cliente':'conta'} #${id}? Esta ação remove o registro do banco.`))return;
  b.disabled=true;
  try{await api(`/api/${type}/${id}`,'DELETE');await refresh();notice('Registro excluído do banco.');}
  catch(e){notice(e.message,true);b.disabled=false;}
});
$('logout').onclick=async()=>{await fetch('/logout',{method:'POST',headers:{[csrf.headerName]:csrf.token}});location.href='/login?logout';};
(async()=>{try{csrf=await api('/api/csrf');await refresh();}catch(e){notice(e.message,true);}})();
