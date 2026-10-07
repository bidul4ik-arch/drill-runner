/* Local write-through cache plus rate-limited Yandex Player cloud saves. */
window.DrillDropSaveStore = class {
  constructor(storage, appId, clock = () => Date.now()) {
    this.storage=storage; this.base='drilldrop-v1-'+appId; this.clock=clock;
    this.key=this.base; this.player=null; this.value=null; this.timer=null;
    this.dirty=false; this.sending=false; this.lastSend=-Infinity;
  }
  read(key) { try { return this.storage.getItem(key); } catch (_) { return null; } }
  put(key,value) { try { this.storage.setItem(key,value); } catch (_) {} }
  parse(value) {
    try { const v=typeof value==='string'?JSON.parse(value):value;
      if(v && v.version===1 && Number.isFinite(v.savedAt) && v.data && typeof v.data==='object' && !Array.isArray(v.data))return v;
    } catch (_) {} return null;
  }
  async connect(sdk) {
    const timeout=p=>Promise.race([p,new Promise((_,reject)=>setTimeout(()=>reject(Error('Cloud timeout')),8000))]);
    try {
      const player=await timeout(sdk.getPlayer());
      const uid=String(player.getUniqueID());
      this.key=this.base+'-player-'+uid;
      this.put(this.base+'-owner',uid);
      let local=this.parse(this.read(this.key));
      // Import the old unscoped save once, never into multiple accounts.
      if(!local && !this.read(this.base+'-migrated')) {
        try { const legacy=JSON.parse(this.read(this.base));
          if(legacy && typeof legacy==='object' && !Array.isArray(legacy))local=this.parse(legacy)||{version:1,savedAt:0,data:legacy};
        } catch (_) {}
        this.put(this.base+'-migrated',uid);
      }
      this.value=local;
      const result=await timeout(player.getData(['drilldrop']));
      const cloud=this.parse(result.drilldrop);
      this.value=cloud && (!local || cloud.savedAt>=local.savedAt)?cloud:local;
      this.player=player;
      if(this.value)this.put(this.key,JSON.stringify(this.value));
      this.dirty=!!this.value && (!cloud || this.value.savedAt>cloud.savedAt);
      this.schedule();
    } catch (_) {
      // No cloud writes after a failed read: an unknown remote save must not be erased.
      this.player=null;
      const owner=this.read(this.base+'-owner');
      if(owner)this.key=this.base+'-player-'+owner;
      this.value=this.value || this.parse(this.read(this.key));
    }
  }
  readSave() {
    if(this.value)return JSON.stringify(this.value.data);
    if(this.key===this.base){const raw=this.read(this.base);const envelope=this.parse(raw);return envelope?JSON.stringify(envelope.data):(raw||'');}
    return '';
  }
  writeSave(raw) {
    let data;try{data=JSON.parse(raw);}catch(_){return;}
    if(!data || typeof data!=='object' || Array.isArray(data))return;
    this.value={version:1,savedAt:Math.max(this.clock(),(this.value?.savedAt||0)+1),data};
    this.put(this.key,JSON.stringify(this.value));this.dirty=true;this.schedule();
  }
  schedule() {
    if(!this.player || !this.dirty || this.timer || this.sending)return;
    this.timer=setTimeout(()=>{this.timer=null;this.flush();},Math.max(1000,10000-(this.clock()-this.lastSend)));
  }
  async flush() {
    if(!this.player || !this.dirty || this.sending)return;
    if(this.clock()-this.lastSend<10000){this.schedule();return;}
    if(this.timer){clearTimeout(this.timer);this.timer=null;}
    this.sending=true;this.lastSend=this.clock();const snapshot=this.value;
    try {
      if(new TextEncoder().encode(JSON.stringify(snapshot)).length>190000)throw Error('Cloud save too large');
      await this.player.setData({drilldrop:snapshot},true);
      if(this.value===snapshot)this.dirty=false;
    } catch (_) { /* Retain the local save and retry, without interrupting play. */ }
    finally {this.sending=false;this.schedule();}
  }
};
