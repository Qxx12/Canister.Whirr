import os, shutil
src = open('index.html').read()
engine = open('engine.js').read()
assert '</script' not in engine
a = '<script src="engine.js"></script>\n'
assert src.count(a) == 1
src = src.replace(a, '')
b = '<script>\nconst LINEUP'
assert src.count(b) == 1
src = src.replace(b, '<script id="engine-src">\n' + engine + '\n</script>\n' + b)
c = '''async function startWorker() {
  try { worker = new Worker("engine.js"); await ping(); return; } catch (e) { worker = null; }
  const src = await (await fetch("engine.js")).text();
  worker = new Worker(URL.createObjectURL(new Blob([src], { type: "text/javascript" })));
}'''
assert src.count(c) == 1
src = src.replace(c, '''async function startWorker() {
  const text = document.getElementById("engine-src").textContent;
  worker = new Worker(URL.createObjectURL(new Blob([text], { type: "text/javascript" })));
  await ping();
}''')
os.makedirs('publish/audio', exist_ok=True)
open('publish/index.html', 'w').write(src)
shutil.copy('bench-data.json', 'publish/bench-data.json')
for f in os.listdir('../site/audio'):
    if f.startswith('ref_'):
        shutil.copy('../site/audio/' + f, 'publish/audio/' + f[:-4] + '.mp4')
print(len(src), sorted(os.listdir('publish/audio')))
