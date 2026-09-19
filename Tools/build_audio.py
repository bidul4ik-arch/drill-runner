import math,wave,struct,os,random
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/Audio/'
def save(name,seconds,fn,loop=False):
 rate=22050
 with wave.open(root+name+'.wav','wb') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'))
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*18000)) for i in range(int(seconds*rate))))
for name,f,d in [('coin',880,.13),('jump',330,.22),('slide',130,.22),('power',660,.4),('hit',70,.45),('ui',440,.12)]:
 save(name,d,lambda t,f=f,d=d: math.sin(math.tau*(f*t+100*t*t))*(1-t/d)**2*.45)
notes=[220,277.18,329.63,440,329.63,277.18,246.94,329.63,196,246.94,293.66,392,293.66,246.94,220,293.66]
def music(t):
 beat=int(t/.3);u=t%.3;f=notes[beat%16]
 return .16*math.sin(math.tau*f*t)*math.exp(-u*9)+.10*math.sin(math.tau*(f/2)*t)+.07*math.sin(math.tau*65*u)*math.exp(-u*35)
save('music',19.2,music)
