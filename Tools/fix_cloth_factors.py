"""Keep neutral dye masks in glTF and write their Blender base-color factors.
Blender 5.2's exporter drops a constant MixRGB multiply factor for these nodes.
"""
import json,struct
from pathlib import Path
FACTORS={'gold':[.52,.235,.038,1],'teal':[.025,.09,.102,1]}
def fix(path):
 b=Path(path).read_bytes();n=struct.unpack('<I',b[12:16])[0];data=json.loads(b[20:20+n])
 for m in data.get('materials',[]):
  if m.get('name') in FACTORS:m.setdefault('pbrMetallicRoughness',{})['baseColorFactor']=FACTORS[m['name']]
 # Blender 5.2 exports per-object Actions separately; combine matching NLA
 # clip names so all three boss assemblies animate as one game clip.
 if Path(path).stem in ['mining_robot','crystal_guardian','giant_drill']:
  grouped={}
  for animation in data.get('animations',[]):
   name=animation['name'].split('.')[0]
   dest=grouped.setdefault(name,{'name':name,'samplers':[],'channels':[]})
   offset=len(dest['samplers']);dest['samplers'].extend(animation['samplers'])
   for channel in animation['channels']:
    channel['sampler']+=offset;dest['channels'].append(channel)
  data['animations']=list(grouped.values())
 j=json.dumps(data,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
 tail=b[20+n:];out=struct.pack('<III',0x46546c67,2,20+len(j)+len(tail))+struct.pack('<II',len(j),0x4e4f534a)+j+tail
 Path(path).write_bytes(out)
if __name__=='__main__':
 root=Path(__file__).resolve().parents[1]/'Art/Models'
 for asset in ['explorer','track','crystal_track','industrial_track','mining_robot','crystal_guardian','giant_drill','drill_attack']:fix(root/(asset+'.glb'))
