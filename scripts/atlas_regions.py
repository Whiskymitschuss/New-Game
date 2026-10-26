"""Read alpha bounds of equal-cell sprite atlases without modifying original images."""
from pathlib import Path
import json
from PIL import Image
root=Path(__file__).resolve().parents[1]/'assets/art'
regions={}
for name,cols,rows in [('heroes',3,1),('enemies',3,2)]:
 im=Image.open(root/(name+'.png')).convert('RGBA')
 items=[]
 for row in range(rows):
  for col in range(cols):
   x1=round(col*im.width/cols);x2=round((col+1)*im.width/cols)
   y1=round(row*im.height/rows);y2=round((row+1)*im.height/rows)
   alpha=im.getchannel('A').crop((x1,y1,x2,y2)).point(lambda p:255 if p>40 else 0)
   bounds=alpha.getbbox()
   if not bounds:raise ValueError(f'Empty atlas cell: {name} {row} {col}')
   a,b,c,d=bounds
   items.append([x1+a,y1+b,c-a,d-b])
 regions[name]=items
(root/'regions.json').write_text(json.dumps(regions,indent=2)+'\n')
print(json.dumps(regions))
