const vm=require('node:vm'),fs=require('node:fs'),assert=require('node:assert/strict');
(async()=>{
const events={},sdkEvents={},calls=[],storage=new Map();
const sdk={environment:{i18n:{lang:'ru'},app:{id:'test'}},features:{LoadingAPI:{ready:()=>calls.push('ready')},GameplayAPI:{start:()=>calls.push('start'),stop:()=>calls.push('stop')}},on:(k,fn)=>sdkEvents[k]=fn};
const context={navigator:{language:'en'},location:{hostname:'test.yandex.ru'},console,localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)},YaGames:{init:async()=>sdk},document:{hidden:false,hasFocus:()=>true,createElement:()=>({}),head:{appendChild:s=>s.onload()},addEventListener:(k,fn)=>events[k]=fn}};
context.window=context;context.addEventListener=(k,fn)=>events[k]=fn;vm.createContext(context);vm.runInContext(fs.readFileSync('Web/yandex.js','utf8'),context);
const p=context.DrillDropPlatform;await p.init();assert.equal(p.language,'ru');assert.equal(p.sdkAvailable,true);
p.ready();p.ready();assert.deepEqual(calls,['ready']);p.gameplay(true);p.gameplay(true);assert.deepEqual(calls,['ready','start']);
let paused;p.setPauseCallback(v=>paused=v);events.blur();assert.equal(paused,true);assert.equal(calls.at(-1),'stop');events.focus();assert.equal(paused,false);
sdkEvents.game_api_pause();assert.equal(paused,true);sdkEvents.game_api_resume();assert.equal(paused,false);
p.gameplay(false);const n=calls.length;sdkEvents.game_api_pause();sdkEvents.game_api_resume();assert.equal(calls.length,n);
p.writeSave('{"coins":50}');assert.equal(p.readSave(),'{"coins":50}');assert.equal(storage.get('drilldrop-v1-test'),'{"coins":50}');
console.log('SDK adapter: language, ready once, gameplay transitions, focus/SDK pause, menu resume, storage PASS');
})();
