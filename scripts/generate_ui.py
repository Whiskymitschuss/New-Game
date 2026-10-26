"""Original scalable SVG upgrade glyphs; resolution-independent 4K UI source assets."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets/ui'
paths={
'damage':'<path d="M42 26L75 59L58 76L25 43Z M70 64L89 83 M78 56L93 71 M37 30L30 23 M58 76L48 86"/>',
'health':'<path d="M57 92C22 69 17 49 31 37C41 29 52 34 57 43C65 29 81 30 89 43C98 59 80 79 57 92Z"/><path d="M44 61H72M58 47V75"/>',
'speed':'<path d="M69 20L36 66H57L48 98L84 53H62Z"/><path d="M20 49H37M17 61H32M23 74H36"/>',
'shield':'<path d="M58 21L88 35V59C88 77 72 89 58 97C44 89 28 77 28 59V35Z"/><path d="M42 57L54 69L76 46"/>',
'energy':'<path d="M51 19L30 60H52L43 99L87 48H64L75 19Z"/>',
'drone':'<path d="M38 48H78V73H38Z M58 48V34 M25 36V59H38 M91 36V59H78 M13 30H38 M78 30H103"/><circle cx="58" cy="60" r="8"/><path d="M44 73L35 84M72 73L81 84"/>',
'ammo':'<path d="M42 84V43L52 24L62 43V84Z M66 84V55L76 36L86 55V84Z M36 84H91 M42 70H62M66 71H86"/>',
'crit':'<circle cx="58" cy="59" r="27"/><circle cx="58" cy="59" r="11"/><path d="M58 18V37 M58 81V101 M17 59H37 M80 59H101"/>',
'poison':'<path d="M47 23H69 M50 23V49L31 80C26 91 33 97 44 97H76C87 97 94 91 88 80L66 49V23 M39 68H80"/><circle cx="52" cy="81" r="3"/><circle cx="70" cy="87" r="3"/>',
'fire':'<path d="M59 21C67 41 44 45 52 61C65 50 72 45 72 36C101 70 83 98 59 98C32 98 20 76 38 52C38 66 43 68 45 68C37 45 58 41 59 21Z"/>',
'economy':'<path d="M58 20L90 39V77L58 97L25 77V39Z M25 39L58 59L90 39 M58 59V97 M42 29L74 49"/>',
'physics':'<circle cx="34" cy="35" r="10"/><circle cx="82" cy="35" r="10"/><circle cx="58" cy="87" r="10"/><path d="M34 46V57L58 76 M82 46V57L58 76 M48 57H68"/>'}
colors=['#5af5c5','#ff7e98','#61dbff','#91baff','#bf9aff','#7aebff','#ffd291','#ffe2a0','#bcff80','#ffad70','#dac0ff','#81fff2']
for (name,shape),color in zip(paths.items(),colors):
 root.joinpath(name+'.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 116 116"><defs><radialGradient id="g"><stop stop-color="{color}" stop-opacity=".22"/><stop offset="1" stop-color="{color}" stop-opacity="0"/></radialGradient></defs><circle cx="58" cy="58" r="57" fill="url(#g)"/><path d="M37 10L17 21L6 42M79 10L99 21L110 42M6 74L17 95L37 106M79 106L99 95L110 74" fill="none" stroke="{color}" stroke-opacity=".3" stroke-width="1"/><g fill="none" stroke="{color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">{shape}</g></svg>')
print('12 original scalable upgrade glyphs generated')
