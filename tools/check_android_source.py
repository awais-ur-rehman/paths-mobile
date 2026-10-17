"""Compile native Kotlin from existing caches only; not a substitute for APK assembly."""
from pathlib import Path
import subprocess, tempfile, zipfile, os
repo=Path(__file__).resolve().parents[1]
cache=Path.home()/'.gradle/caches/modules-2/files-2.1'
sdk=Path(os.environ.get('ANDROID_HOME',Path.home()/'Library/Android/sdk'))
with tempfile.TemporaryDirectory(prefix='paths-kotlin-') as temp:
 out=Path(temp)
 compiler=[]
 for group,artifact,version in [('org.jetbrains.kotlin','kotlin-compiler-embeddable','2.4.0'),('org.jetbrains.kotlin','kotlin-stdlib','2.4.0'),('org.jetbrains.kotlin','kotlin-reflect','2.2.21'),('org.jetbrains.kotlin','kotlin-script-runtime','2.4.0'),('org.jetbrains.kotlinx','kotlinx-coroutines-core-jvm','1.10.2'),('org.jetbrains','annotations','13.0')]:
  compiler+=list((cache/group/artifact/version).glob('*/*.jar'))
 dependencies=[sdk/'platforms/android-36/android.jar']
 dependencies+=list((cache/'org.jetbrains.kotlin/kotlin-stdlib/2.4.0').glob('*/*.jar'))
 for group in ['com.google.android.gms','io.flutter','androidx.lifecycle','androidx.annotation']:
  dependencies+=list((cache/group).glob('*/*/*/*.jar'))
  for i,aar in enumerate((cache/group).glob('*/*/*/*.aar')):
   with zipfile.ZipFile(aar) as z:
    if 'classes.jar' in z.namelist():
     dest=out/f'{group}-{i}.jar';dest.write_bytes(z.read('classes.jar'));dependencies.append(dest)
 # Compile resources are Android-generated; use that actual output if available.
 generated=list((repo/'build').glob('app/intermediates/**/R.jar'))
 if generated: dependencies+=generated
 else:
  # Only resource IDs are unavailable without resource assembly. Omit the service's R reference via a temporary source copy.
  pass
 sources=list((repo/'android/app/src/main/kotlin').rglob('*.kt'))+list((repo/'android/app/src/debug/kotlin').rglob('*.kt'))
 # Compile Location core separately if Android-generated R is blocked; Activity can still be checked with embedding.
 if not generated:
  copied=[]
  for f in sources:
   dest=out/f.name;dest.write_text(f.read_text().replace('com.paths.mobile.R.drawable.paths_symbol','android.R.drawable.ic_menu_mylocation'));copied.append(dest)
  sources=copied
 cmd=['java','-cp',os.pathsep.join(map(str,compiler)),'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler','-no-stdlib','-no-reflect','-jvm-target','17','-classpath',os.pathsep.join(map(str,dependencies)),'-d',str(out/'classes')]+list(map(str,sources))
 result=subprocess.run(cmd);raise SystemExit(result.returncode)
