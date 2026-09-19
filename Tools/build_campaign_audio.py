import math,wave,struct,os
root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))+'/Audio/'
def save(name,duration,fn):
 rate=22050
 with wave.open(root+name+'.wav','wb') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'))
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*20000)) for i in range(int(duration*rate))))
for name,f in [('warning',520),('boss_attack',100),('boss_hit',210),('boost',160),('victory',660)]:
 save(name,.6,lambda t,f=f:math.sin(math.tau*(f*t+200*t*t))*.3*(1-t/.6))
for name,f in [('mine',82),('cave',146.83),('factory',55)]:
 save(name,8,lambda t,f=f:(.12*math.sin(math.tau*f*t)+.06*math.sin(math.tau*f*2*t))*(.7+.3*math.sin(math.pi*t/4)))
